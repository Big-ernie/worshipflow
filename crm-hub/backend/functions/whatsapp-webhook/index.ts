
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const url = Deno.env.get("SUPABASE_URL") || "";
let serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
if (!serviceKey) {
  try {
    const keys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") || "{}");
    serviceKey = keys.default || "";
  } catch (_) {}
}
const sb = createClient(url, serviceKey, { auth: { persistSession: false } });

function textResponse(body: string, status = 200) {
  return new Response(body, { status, headers: { "content-type": "text/plain; charset=utf-8" } });
}
function jsonResponse(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });
}
function hex(buf: ArrayBuffer) {
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, "0")).join("");
}
async function validSignature(body: string, signature: string | null, secret: string) {
  if (!signature || !secret) return false;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body));
  const expected = "sha256=" + hex(sig);
  if (expected.length !== signature.length) return false;
  let ok = 0;
  for (let i = 0; i < expected.length; i++) ok |= expected.charCodeAt(i) ^ signature.charCodeAt(i);
  return ok === 0;
}
async function sendText(connection: any, to: string, body: string) {
  const { data: token, error } = await sb.rpc("get_whatsapp_access_token", { p_connection: connection.id });
  if (error || !token) return { ok: false, error: error?.message || "Missing token" };
  const endpoint = "https://graph.facebook.com/" + encodeURIComponent(connection.external_account_id) + "/messages";
  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "authorization": "Bearer " + token, "content-type": "application/json" },
    body: JSON.stringify({ messaging_product: "whatsapp", to, type: "text", text: { body } })
  });
  const payload = await res.json().catch(() => ({}));
  return { ok: res.ok, payload };
}
async function sendList(connection: any, to: string, body: string, buttonText: string, rows: any[]) {
  const { data: token, error } = await sb.rpc("get_whatsapp_access_token", { p_connection: connection.id });
  if (error || !token) return { ok: false, error: error?.message || "Missing token" };
  const endpoint = "https://graph.facebook.com/" + encodeURIComponent(connection.external_account_id) + "/messages";
  const cleanRows = rows.slice(0,10).map((r:any,i:number)=>({
    id: String(r.id || ("row_"+(i+1))).slice(0,200),
    title: String(r.title || ("Option "+(i+1))).slice(0,24),
    description: r.description ? String(r.description).slice(0,72) : undefined
  }));
  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "authorization": "Bearer " + token, "content-type": "application/json" },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to,
      type: "interactive",
      interactive: {
        type: "list",
        body: { text: body.slice(0,1024) },
        action: {
          button: buttonText.slice(0,20),
          sections: [{ title: "Available options", rows: cleanRows }]
        }
      }
    })
  });
  const payload = await res.json().catch(() => ({}));
  return { ok: res.ok, payload };
}
async function recordOutbound(orgId: string, conversationId: string, body: string, providerResult: any, messageType = "text") {
  await sb.from("messages").insert({
    organization_id: orgId,
    conversation_id: conversationId,
    direction: "outbound",
    message_type: messageType,
    body,
    provider_message_id: providerResult?.payload?.messages?.[0]?.id || null,
    status: providerResult?.ok ? "sent" : "error",
    payload: providerResult?.payload || {}
  });
  await sb.from("conversations").update({ last_message_at: new Date().toISOString(), last_outbound_at: new Date().toISOString() }).eq("id", conversationId);
}
async function reply(connection: any, conversation: any, to: string, body: string) {
  const result = await sendText(connection, to, body);
  await recordOutbound(connection.organization_id, conversation.id, body, result);
  return result;
}
async function replyList(connection: any, conversation: any, to: string, body: string, buttonText: string, rows: any[], fallback: string) {
  const result = await sendList(connection, to, body, buttonText, rows);
  if (result.ok) {
    await recordOutbound(connection.organization_id, conversation.id, body, result, "interactive");
    return result;
  }
  return await reply(connection, conversation, to, fallback);
}
async function getConnection(phoneNumberId: string) {
  const { data } = await sb.from("channel_connections")
    .select("*")
    .eq("channel_type", "whatsapp")
    .eq("external_account_id", phoneNumberId)
    .maybeSingle();
  return data;
}
async function ensureContact(orgId: string, waId: string, name: string | null) {
  let { data } = await sb.from("contacts").select("*")
    .eq("organization_id", orgId)
    .eq("whatsapp", waId)
    .maybeSingle();
  if (data) return data;
  const firstName = (name || "WhatsApp Lead").trim() || "WhatsApp Lead";
  const ins = await sb.from("contacts").insert({
    organization_id: orgId,
    first_name: firstName,
    whatsapp: waId,
    phone: waId,
    preferred_channel: "WhatsApp"
  }).select("*").single();
  return ins.data;
}
async function ensureConversation(orgId: string, connectionId: string, contactId: string, waId: string) {
  let { data } = await sb.from("conversations").select("*")
    .eq("organization_id", orgId)
    .eq("channel_connection_id", connectionId)
    .eq("external_thread_id", waId)
    .maybeSingle();
  if (data) return data;
  const ins = await sb.from("conversations").insert({
    organization_id: orgId,
    channel_connection_id: connectionId,
    contact_id: contactId,
    external_thread_id: waId,
    status: "open",
    last_message_at: new Date().toISOString()
  }).select("*").single();
  return ins.data;
}
async function getBookableServices(orgId: string) {
  const { data } = await sb.from("products_services")
    .select("id,name,duration_minutes,price,currency")
    .eq("organization_id", orgId)
    .eq("active", true)
    .eq("is_bookable", true)
    .order("name");
  return data || [];
}
async function activeSession(orgId: string, conversationId: string) {
  const { data } = await sb.from("booking_sessions").select("*")
    .eq("organization_id", orgId)
    .eq("conversation_id", conversationId)
    .gt("expires_at", new Date().toISOString())
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  return data;
}
function parseService(text: string, services: any[]) {
  const n = Number.parseInt(text.trim(), 10);
  if (Number.isFinite(n) && n >= 1 && n <= services.length) return services[n - 1];
  const t = text.trim().toLowerCase();
  return services.find((s) => s.name.toLowerCase() === t) || services.find((s) => s.name.toLowerCase().includes(t));
}
function localDateInZone(timeZone: string) {
  const parts = new Intl.DateTimeFormat("en-US",{timeZone,year:"numeric",month:"2-digit",day:"2-digit"}).formatToParts(new Date());
  const map:any={}; for(const p of parts) map[p.type]=p.value;
  return map.year+"-"+map.month+"-"+map.day;
}
async function sendServiceChoices(connection:any, conversation:any, from:string, services:any[]) {
  const textList = services.map((s:any,i:number) => String(i+1)+". "+s.name).join("\n");
  if (services.length <= 10) {
    const rows = services.map((s:any,i:number)=>({
      id:"service:"+s.id,
      title:s.name,
      description:s.price!=null ? ((s.currency||"")+" "+Number(s.price).toLocaleString()).trim() : undefined
    }));
    await replyList(connection,conversation,from,"Great. Choose the service you would like to book.","Choose service",rows,"Great. Which service would you like to book?\n\n"+textList+"\n\nReply with the number or service name.");
  } else {
    await reply(connection,conversation,from,"Great. Which service would you like to book?\n\n"+textList+"\n\nReply with the number or service name.");
  }
}
async function getSlotInfo(orgId:string, serviceId:string, date:string) {
  const { data, error } = await sb.rpc("get_booking_slots_server",{p_org:orgId,p_service:serviceId,p_date:date});
  if (error) return {configured:false,slots:[],error:error.message};
  return {configured:!!data?.configured,slots:Array.isArray(data?.slots)?data.slots:[],error:null};
}
async function sendSlotChoices(connection:any,conversation:any,from:string,date:string,slots:string[]) {
  const textList=slots.map((s:string,i:number)=>String(i+1)+". "+s).join("\n");
  if(slots.length<=10){
    const rows=slots.map((s:string)=>({id:"slot:"+s,title:s,description:"Available on "+date}));
    await replyList(connection,conversation,from,"Choose an available time for "+date+".","Choose time",rows,"Available times for "+date+":\n\n"+textList+"\n\nReply with the number or time.");
  } else {
    await reply(connection,conversation,from,"Available times for "+date+":\n\n"+textList+"\n\nReply with the number or time.");
  }
}
async function handleBooking(connection: any, conversation: any, contact: any, from: string, body: string) {
  const orgId = connection.organization_id;
  const services = await getBookableServices(orgId);
  if (!services.length) return false;
  let session = await activeSession(orgId, conversation.id);
  const lower = body.trim().toLowerCase();

  if (session && lower === "cancel") {
    await sb.from("booking_sessions").update({ state:"cancelled", expires_at:new Date().toISOString(), updated_at:new Date().toISOString() }).eq("id",session.id);
    await reply(connection,conversation,from,"Booking cancelled. Reply BOOK whenever you want to start again.");
    return true;
  }

  if (session && (lower === "restart" || lower === "start over")) {
    await sb.from("booking_sessions").update({
      state:"awaiting_service",
      product_service_id:null,
      requested_date:null,
      requested_time:null,
      appointment_id:null,
      context:{},
      expires_at:new Date(Date.now()+2*60*60*1000).toISOString(),
      updated_at:new Date().toISOString()
    }).eq("id",session.id);
    await sendServiceChoices(connection,conversation,from,services);
    return true;
  }

  if (!session && (lower === "book" || lower.includes("appointment") || lower.includes("booking"))) {
    const ins = await sb.from("booking_sessions").insert({
      organization_id: orgId,
      conversation_id: conversation.id,
      contact_id: contact.id,
      state: "awaiting_service"
    }).select("*").single();
    session = ins.data;
    await sendServiceChoices(connection, conversation, from, services);
    return true;
  }
  if (!session) return false;

  if (session.state === "awaiting_service") {
    const service = parseService(body, services);
    if (!service) {
      await reply(connection, conversation, from, "I couldn't match that service. Choose one from the list, or reply RESTART to begin again.");
      return true;
    }
    await sb.from("booking_sessions").update({
      state: "awaiting_date",
      product_service_id: service.id,
      context:{service_name:service.name},
      updated_at: new Date().toISOString()
    }).eq("id", session.id);
    await reply(connection, conversation, from, "What date would you like for "+service.name+"? Reply in YYYY-MM-DD format, for example 2026-10-12.\n\nReply CANCEL to stop.");
    return true;
  }

  if (session.state === "awaiting_date") {
    const requested=body.trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(requested)) {
      await reply(connection, conversation, from, "Please send the date as YYYY-MM-DD, for example 2026-10-12.");
      return true;
    }
    const {data:org}=await sb.from("organizations").select("timezone").eq("id",orgId).single();
    const today=localDateInZone(org?.timezone||"UTC");
    if(requested<today){
      await reply(connection,conversation,from,"That date has already passed. Please send a future date in YYYY-MM-DD format.");
      return true;
    }

    const slotInfo=await getSlotInfo(orgId,session.product_service_id,requested);
    if(slotInfo.configured && slotInfo.slots.length===0){
      await reply(connection,conversation,from,"There are no open times on "+requested+". Please send another date.");
      return true;
    }

    const context={...(session.context||{}),available_slots:slotInfo.configured?slotInfo.slots:null};
    await sb.from("booking_sessions").update({
      state:"awaiting_time",
      requested_date:requested,
      context,
      updated_at:new Date().toISOString()
    }).eq("id",session.id);

    if(slotInfo.configured){
      await sendSlotChoices(connection,conversation,from,requested,slotInfo.slots);
    }else{
      await reply(connection,conversation,from,"What time works for you? Reply in 24-hour HH:MM format, for example 14:30.");
    }
    return true;
  }

  if (session.state === "awaiting_time") {
    let t=body.trim();
    const slots=Array.isArray(session.context?.available_slots)?session.context.available_slots:null;
    if(slots){
      const n=Number.parseInt(t,10);
      if(Number.isFinite(n)&&n>=1&&n<=slots.length)t=slots[n-1];
      if(!slots.includes(t)){
        await reply(connection,conversation,from,"Please choose one of the available times shown. Reply with the number or exact time.");
        return true;
      }
    }else if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(t)) {
      await reply(connection, conversation, from, "Please send the time in 24-hour HH:MM format, for example 14:30.");
      return true;
    }

    const { data: appointmentId, error } = await sb.rpc("create_whatsapp_appointment", {
      p_org: orgId,
      p_contact: contact.id,
      p_service: session.product_service_id,
      p_date: session.requested_date,
      p_time: t,
      p_conversation: conversation.id
    });

    if (error) {
      const fresh=await getSlotInfo(orgId,session.product_service_id,session.requested_date);
      if(fresh.configured && fresh.slots.length){
        await sb.from("booking_sessions").update({
          context:{...(session.context||{}),available_slots:fresh.slots},
          updated_at:new Date().toISOString()
        }).eq("id",session.id);
        await reply(connection,conversation,from,"That time is no longer available. Here are the remaining options:");
        await sendSlotChoices(connection,conversation,from,session.requested_date,fresh.slots);
      }else{
        await sb.from("booking_sessions").update({state:"awaiting_date",context:{...(session.context||{}),available_slots:null},updated_at:new Date().toISOString()}).eq("id",session.id);
        await reply(connection,conversation,from,"That time could not be booked. Please send another date and I’ll check availability again.");
      }
      return true;
    }

    const { data: appt } = await sb.from("appointments")
      .select("booking_reference,start_at,end_at")
      .eq("id", appointmentId).single();

    await sb.from("booking_sessions").update({
      state: "complete",
      requested_time: t,
      appointment_id: appointmentId,
      expires_at:new Date().toISOString(),
      updated_at: new Date().toISOString()
    }).eq("id", session.id);

    await reply(connection, conversation, from,
      "Your appointment request is in the CRM.\n\nReference: "+(appt?.booking_reference||"created")+
      "\nDate: "+session.requested_date+
      "\nTime: "+t+
      "\n\nThe team will confirm it shortly."
    );
    return true;
  }
  return false;
}


async function getWhatsAppItems(orgId:string) {
  const { data } = await sb.from("products_services")
    .select("id,name,description,price,currency,is_orderable,is_bookable,whatsapp_catalog_enabled")
    .eq("organization_id",orgId)
    .eq("active",true)
    .or("whatsapp_catalog_enabled.eq.true,is_orderable.eq.true,is_bookable.eq.true")
    .order("sort_order")
    .order("name")
    .limit(10);
  return data || [];
}
async function activeIntake(orgId:string,conversationId:string) {
  const { data } = await sb.from("intake_sessions").select("*")
    .eq("organization_id",orgId)
    .eq("conversation_id",conversationId)
    .gt("expires_at",new Date().toISOString())
    .order("updated_at",{ascending:false})
    .limit(1).maybeSingle();
  return data;
}
async function sendCatalog(connection:any,conversation:any,from:string,lead="Choose a product or service.") {
  const items=await getWhatsAppItems(connection.organization_id);
  if(!items.length){
    await reply(connection,conversation,from,"Our catalog is not published in WhatsApp yet. Send us what you need and the team will help from the CRM.");
    return [];
  }
  const rows=items.map((x:any)=>({
    id:"catalog:"+x.id,
    title:String(x.name||"Item").slice(0,24),
    description:String(x.price!=null?((x.currency||"")+" "+Number(x.price).toLocaleString()).trim():(x.description||"")).slice(0,72)
  }));
  const fallback=lead+"\n\n"+items.map((x:any,i:number)=>String(i+1)+". "+x.name+(x.price!=null?" — "+(x.currency||"")+" "+Number(x.price).toLocaleString():"")).join("\n");
  await replyList(connection,conversation,from,lead,"View options",rows,fallback);
  return items;
}
function parseCatalogItem(body:string,selectionId:string,items:any[]) {
  if(selectionId && selectionId.startsWith("catalog:")){
    const id=selectionId.slice("catalog:".length);
    return items.find((x:any)=>x.id===id);
  }
  const n=Number.parseInt(body.trim(),10);
  if(Number.isFinite(n)&&n>=1&&n<=items.length) return items[n-1];
  const t=body.trim().toLowerCase();
  return items.find((x:any)=>x.name.toLowerCase()===t) || items.find((x:any)=>x.name.toLowerCase().includes(t));
}
async function sendActionMenu(connection:any,conversation:any,from:string) {
  const rows=[
    {id:"action:catalog",title:"Browse catalog",description:"See products and services"},
    {id:"action:quote",title:"Request a quote",description:"Send a structured quote request"},
    {id:"action:order",title:"Place an order",description:"Start a structured order request"},
    {id:"action:book",title:"Book appointment",description:"Choose a bookable service and time"}
  ];
  await replyList(connection,conversation,from,"How can we help?","Choose action",rows,
    "How can we help?\n\nReply CATALOG, QUOTE, ORDER, or BOOK.");
}
async function startIntake(connection:any,conversation:any,contact:any,from:string,type:string) {
  const items=await getWhatsAppItems(connection.organization_id);
  if(!items.length){
    await reply(connection,conversation,from,"Send us the product or service you need and the team will continue with you here on WhatsApp.");
    return true;
  }
  await sb.from("intake_sessions").insert({
    organization_id:connection.organization_id,
    conversation_id:conversation.id,
    contact_id:contact.id,
    request_type:type,
    state:"awaiting_item",
    expires_at:new Date(Date.now()+2*60*60*1000).toISOString()
  });
  await sendCatalog(connection,conversation,from,type==="quote"?"Choose the item or service you want quoted.":"Choose the item you want to order.");
  return true;
}
async function finishIntake(connection:any,conversation:any,contact:any,from:string,session:any,item:any,notes:string|null) {
  const qty=Number(session.context?.quantity||1);
  const total=item?.price!=null?Number(item.price)*qty:0;
  const ref="RQ-"+crypto.randomUUID().replaceAll("-","").slice(0,8).toUpperCase();
  const type=session.request_type==="order"?"order":"quote";
  const ins=await sb.from("customer_requests").insert({
    organization_id:connection.organization_id,
    contact_id:contact.id,
    conversation_id:conversation.id,
    request_number:ref,
    request_type:type,
    source:"whatsapp",
    status:"ready",
    title:(type==="order"?"WhatsApp order: ":"WhatsApp quote: ")+(item?.name||"Request"),
    notes,
    total,
    currency:item?.currency||"GHS",
    next_action:type==="order"?"Confirm order, payment and fulfillment details":"Review requirements and prepare quote",
    metadata:{whatsapp_from:from}
  }).select("*").single();
  if(ins.error){
    await reply(connection,conversation,from,"I captured the details, but the CRM could not create the request. The team can still see this conversation and will follow up.");
    return true;
  }
  await sb.from("request_items").insert({
    organization_id:connection.organization_id,
    request_id:ins.data.id,
    product_service_id:item?.id||null,
    item_name:item?.name||"Requested item",
    quantity:qty,
    unit_price:item?.price??null,
    currency:item?.currency||"GHS",
    notes
  });

  const dealTitle=(type==="order"?"WhatsApp Order — ":"WhatsApp Quote — ")+(item?.name||contact?.first_name||"Customer");
  const d=await sb.from("deals").insert({
    organization_id:connection.organization_id,
    title:dealTitle,
    contact_id:contact.id,
    product_service_id:item?.id||null,
    stage:"New Enquiry",
    priority:"Medium",
    amount:total,
    currency:item?.currency||"GHS",
    lead_source:"WhatsApp",
    next_action:type==="order"?"Confirm order and payment/fulfillment":"Review WhatsApp quote request",
    next_followup_at:new Date().toISOString()
  }).select("id").single();
  if(d.data?.id){
    await sb.from("customer_requests").update({linked_deal_id:d.data.id}).eq("id",ins.data.id);
  }

  await sb.from("intake_sessions").update({
    state:"complete",request_id:ins.data.id,expires_at:new Date().toISOString(),updated_at:new Date().toISOString()
  }).eq("id",session.id);

  const priceLine=item?.price!=null?"\nEstimated value: "+(item.currency||"GHS")+" "+total.toLocaleString():"";
  await reply(connection,conversation,from,
    "Done. Your "+(type==="order"?"order request":"quote request")+" is in the CRM.\n\nReference: "+ref+
    "\nItem: "+(item?.name||"Request")+"\nQuantity: "+qty+priceLine+
    "\n\nThe team can continue with you here on WhatsApp."
  );
  return true;
}
async function handleSalesIntake(connection:any,conversation:any,contact:any,from:string,body:string,selectionId:string) {
  const orgId=connection.organization_id;
  const lower=body.trim().toLowerCase();
  const actionId=selectionId?.startsWith("action:")?selectionId.slice(7):"";
  let session=await activeIntake(orgId,conversation.id);

  if(session && lower==="cancel"){
    await sb.from("intake_sessions").update({state:"cancelled",expires_at:new Date().toISOString(),updated_at:new Date().toISOString()}).eq("id",session.id);
    await reply(connection,conversation,from,"Request cancelled. Reply QUOTE or ORDER whenever you want to start again.");
    return true;
  }
  if(session && (lower==="restart"||lower==="start over")){
    await sb.from("intake_sessions").update({
      state:"awaiting_item",product_service_id:null,request_id:null,context:{},
      expires_at:new Date(Date.now()+2*60*60*1000).toISOString(),updated_at:new Date().toISOString()
    }).eq("id",session.id);
    await sendCatalog(connection,conversation,from,"Choose an item or service.");
    return true;
  }

  if(!session && (actionId==="catalog"||lower==="catalog"||lower==="menu"||lower==="products"||lower==="services")){
    await sendCatalog(connection,conversation,from);
    return true;
  }
  if(!session && (actionId==="quote"||lower==="quote"||lower.includes("quotation")||lower.includes("get a quote"))){
    return await startIntake(connection,conversation,contact,from,"quote");
  }
  if(!session && (actionId==="order"||lower==="order"||lower==="buy"||lower.includes("place an order"))){
    return await startIntake(connection,conversation,contact,from,"order");
  }

  if(!session && selectionId?.startsWith("catalog:")){
    const items=await getWhatsAppItems(orgId);
    const item=parseCatalogItem(body,selectionId,items);
    if(!item) return false;
    const ins=await sb.from("intake_sessions").insert({
      organization_id:orgId,conversation_id:conversation.id,contact_id:contact.id,
      request_type:"enquiry",state:"awaiting_intent",product_service_id:item.id,
      context:{item_name:item.name,item_price:item.price,item_currency:item.currency,is_orderable:item.is_orderable},
      expires_at:new Date(Date.now()+2*60*60*1000).toISOString()
    }).select("*").single();
    session=ins.data;
    await reply(connection,conversation,from,"You selected "+item.name+". Reply QUOTE for a quote"+(item.is_orderable?" or ORDER to place an order":"")+". Reply CANCEL to stop.");
    return true;
  }

  if(!session) return false;
  const items=await getWhatsAppItems(orgId);

  if(session.state==="awaiting_intent"){
    const item=items.find((x:any)=>x.id===session.product_service_id);
    if(actionId==="quote"||lower==="quote"){
      await sb.from("intake_sessions").update({request_type:"quote",state:"awaiting_quantity",updated_at:new Date().toISOString()}).eq("id",session.id);
      await reply(connection,conversation,from,"How many "+(item?.name||"items")+" do you need?");
      return true;
    }
    if(actionId==="order"||lower==="order"){
      if(!item?.is_orderable){
        await reply(connection,conversation,from,"This item is set up for enquiries/quotes rather than direct ordering. Reply QUOTE to continue.");
        return true;
      }
      await sb.from("intake_sessions").update({request_type:"order",state:"awaiting_quantity",updated_at:new Date().toISOString()}).eq("id",session.id);
      await reply(connection,conversation,from,"How many "+item.name+" do you need?");
      return true;
    }
    await reply(connection,conversation,from,"Reply QUOTE"+(item?.is_orderable?" or ORDER":"")+" to continue, or CANCEL.");
    return true;
  }

  if(session.state==="awaiting_item"){
    const item=parseCatalogItem(body,selectionId,items);
    if(!item){
      await reply(connection,conversation,from,"I couldn't match that item. Choose one from the list or reply RESTART.");
      return true;
    }
    if(session.request_type==="order"&&!item.is_orderable){
      await reply(connection,conversation,from,"That item is not enabled for direct ordering. Choose another item, or reply CANCEL and start a QUOTE request.");
      return true;
    }
    await sb.from("intake_sessions").update({
      state:"awaiting_quantity",product_service_id:item.id,
      context:{item_name:item.name,item_price:item.price,item_currency:item.currency,is_orderable:item.is_orderable},
      updated_at:new Date().toISOString()
    }).eq("id",session.id);
    await reply(connection,conversation,from,"How many "+item.name+" do you need? Reply with a number.");
    return true;
  }

  if(session.state==="awaiting_quantity"){
    const qty=Number(body.trim());
    if(!Number.isFinite(qty)||qty<=0){
      await reply(connection,conversation,from,"Please send a quantity greater than 0.");
      return true;
    }
    await sb.from("intake_sessions").update({
      state:"awaiting_notes",context:{...(session.context||{}),quantity:qty},updated_at:new Date().toISOString()
    }).eq("id",session.id);
    await reply(connection,conversation,from,"Any size, specification, delivery or timing details we should know? Reply SKIP if there is nothing else.");
    return true;
  }

  if(session.state==="awaiting_notes"){
    const item=items.find((x:any)=>x.id===session.product_service_id) || {
      id:session.product_service_id,name:session.context?.item_name,
      price:session.context?.item_price,currency:session.context?.item_currency||"GHS"
    };
    const notes=lower==="skip"?null:body.trim();
    return await finishIntake(connection,conversation,contact,from,session,item,notes);
  }
  return false;
}

Deno.serve(async (req: Request) => {
  const reqUrl = new URL(req.url);

  if (req.method === "GET") {
    const mode = reqUrl.searchParams.get("hub.mode");
    const token = reqUrl.searchParams.get("hub.verify_token");
    const challenge = reqUrl.searchParams.get("hub.challenge") || "";
    if (mode !== "subscribe" || !token) return textResponse("invalid", 400);

    const { data: connection } = await sb.from("channel_connections")
      .select("*")
      .eq("channel_type", "whatsapp")
      .eq("configuration->>verify_token", token)
      .maybeSingle();
    if (!connection) return textResponse("forbidden", 403);
    await sb.rpc("mark_whatsapp_connected", { p_connection: connection.id });
    return textResponse(challenge, 200);
  }

  if (req.method !== "POST") return textResponse("method not allowed", 405);
  const raw = await req.text();
  let payload: any;
  try { payload = JSON.parse(raw); } catch (_) { return jsonResponse({ error: "invalid json" }, 400); }

  const change = payload?.entry?.[0]?.changes?.[0]?.value;
  const phoneNumberId = change?.metadata?.phone_number_id;
  if (!phoneNumberId) return jsonResponse({ ok: true });

  const connection = await getConnection(phoneNumberId);
  if (!connection) return jsonResponse({ ok: true });

  const { data: appSecret } = await sb.rpc("get_whatsapp_app_secret", { p_connection: connection.id });
  const signature = req.headers.get("x-hub-signature-256");
  if (!await validSignature(raw, signature, appSecret || "")) return jsonResponse({ error: "invalid signature" }, 401);

  const delivery = change?.statuses?.[0];
  if (delivery?.id) {
    await sb.from("messages")
      .update({ status: delivery.status || "unknown" })
      .eq("organization_id", connection.organization_id)
      .eq("provider_message_id", delivery.id);
    return jsonResponse({ ok: true, status_updated: true });
  }

  const msg = change?.messages?.[0];
  if (!msg) return jsonResponse({ ok: true });

  const from = msg.from;
  const selectionId = msg?.interactive?.button_reply?.id || msg?.interactive?.list_reply?.id || msg?.button?.payload || "";
  const body = msg?.text?.body || msg?.button?.text || msg?.interactive?.button_reply?.title || msg?.interactive?.list_reply?.title || "";
  const profileName = change?.contacts?.[0]?.profile?.name || null;
  const contact = await ensureContact(connection.organization_id, from, profileName);
  const conversation = await ensureConversation(connection.organization_id, connection.id, contact.id, from);

  if (msg.id) {
    const { data: existing } = await sb.from("messages")
      .select("id")
      .eq("organization_id", connection.organization_id)
      .eq("provider_message_id", msg.id)
      .maybeSingle();
    if (existing) return jsonResponse({ ok: true, duplicate: true });
  }

  const inbound = await sb.from("messages").insert({
    organization_id: connection.organization_id,
    conversation_id: conversation.id,
    direction: "inbound",
    provider_message_id: msg.id || null,
    message_type: msg.type || "text",
    body,
    payload: msg,
    status: "received",
    occurred_at: new Date(Number(msg.timestamp || Math.floor(Date.now()/1000))*1000).toISOString()
  });
  if (inbound.error) {
    if (inbound.error.code === "23505") return jsonResponse({ ok: true, duplicate: true });
    return jsonResponse({ error: inbound.error.message }, 500);
  }
  await sb.from("conversations").update({ last_message_at: new Date().toISOString(), last_inbound_at: new Date().toISOString(), status: "open" }).eq("id", conversation.id);

  if (body) {
    const salesHandled = await handleSalesIntake(connection, conversation, contact, from, body, selectionId);
    if (!salesHandled) {
      const booked = await handleBooking(connection, conversation, contact, from, body);
      if (!booked) {
        const lower=body.trim().toLowerCase();
        const actionId=selectionId?.startsWith("action:")?selectionId.slice(7):"";
        if(actionId==="book"){
          await handleBooking(connection,conversation,contact,from,"book appointment");
        } else if(["hi","hello","hey","help","start"].includes(lower)){
          await sendActionMenu(connection,conversation,from);
        }
      }
    }
  }
  return jsonResponse({ ok: true });
});
