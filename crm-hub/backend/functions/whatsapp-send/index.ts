import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const url=Deno.env.get("SUPABASE_URL")||"";
let serviceKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||"";
if(!serviceKey){try{const k=JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")||"{}");serviceKey=k.default||""}catch(_){}}
const admin=createClient(url,serviceKey,{auth:{persistSession:false}});
function allowedOrigin(req:Request){
  const o=req.headers.get("origin")||"";
  if(o==="https://big-ernie-crm-hub.vercel.app") return o;
  if(/^https:\/\/big-ernie-crm-[a-z0-9-]+-big-ernie\.vercel\.app$/i.test(o)) return o;
  return "https://big-ernie-crm-hub.vercel.app";
}
function responseHeaders(req:Request){return {"access-control-allow-origin":allowedOrigin(req),"vary":"Origin","access-control-allow-headers":"authorization, x-client-info, apikey, content-type","access-control-allow-methods":"POST, OPTIONS","content-type":"application/json; charset=utf-8"}}
const rank:{[k:string]:number}={none:0,view:1,edit:2,admin:3};

async function tokenFor(connectionId:string){
  const {data,error}=await admin.rpc("get_whatsapp_access_token",{p_connection:connectionId});
  if(error||!data) throw new Error(error?.message||"WhatsApp access token unavailable");
  return data as string;
}
async function sendMeta(connection:any,to:string,payload:any){
  const token=await tokenFor(connection.id);
  const res=await fetch("https://graph.facebook.com/"+encodeURIComponent(connection.external_account_id)+"/messages",{
    method:"POST",headers:{authorization:"Bearer "+token,"content-type":"application/json"},
    body:JSON.stringify({messaging_product:"whatsapp",to,...payload})
  });
  const data=await res.json().catch(()=>({}));
  if(!res.ok) throw new Error(data?.error?.message||"WhatsApp rejected the message");
  return data;
}
async function recordOutbound(org:string,conversation:string,body:string,payload:any,type="text"){
  await admin.from("messages").insert({
    organization_id:org,conversation_id:conversation,direction:"outbound",
    provider_message_id:payload?.messages?.[0]?.id||null,message_type:type,body,
    payload,status:"sent",occurred_at:new Date().toISOString()
  });
  await admin.from("conversations").update({
    last_message_at:new Date().toISOString(),last_outbound_at:new Date().toISOString()
  }).eq("id",conversation).eq("organization_id",org);
}
async function assertAccess(org:string,userId:string){
  const {data:m}=await admin.from("workspace_memberships").select("id,role,active")
    .eq("organization_id",org).eq("user_id",userId).eq("active",true).maybeSingle();
  if(!m) throw new Error("Workspace access required");
  const {data:override}=await admin.from("member_module_access").select("access_level")
    .eq("membership_id",m.id).eq("module_key","whatsapp").maybeSingle();
  let level=override?.access_level;
  if(!level){
    const {data:def}=await admin.from("role_module_defaults").select("access_level")
      .eq("role",m.role).eq("module_key","whatsapp").maybeSingle();
    level=def?.access_level||"none";
  }
  if((rank[level]||0)<rank.edit) throw new Error("WhatsApp edit access required");
}
async function insideReplyWindow(org:string,conversation:string){
  const {data}=await admin.from("messages").select("occurred_at").eq("organization_id",org)
    .eq("conversation_id",conversation).eq("direction","inbound")
    .order("occurred_at",{ascending:false}).limit(1).maybeSingle();
  if(!data?.occurred_at) return false;
  return Date.now()-new Date(data.occurred_at).getTime() < 24*60*60*1000;
}

Deno.serve(async(req)=>{
  const out=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:responseHeaders(req)});
  if(req.method==="OPTIONS") return new Response("ok",{headers:responseHeaders(req)});
  if(req.method!=="POST") return out({error:"Method not allowed"},405);
  try{
    const jwt=(req.headers.get("authorization")||"").replace(/^Bearer\s+/i,"");
    const {data:u,error:ue}=await admin.auth.getUser(jwt);
    if(ue||!u.user) return out({error:"Invalid session"},401);

    const b=await req.json();
    const org=String(b.organization_id||"");
    const conversationId=String(b.conversation_id||"");
    const action=String(b.action||"text");
    if(!org||!conversationId) return out({error:"organization_id and conversation_id are required"},400);
    await assertAccess(org,u.user.id);

    const {data:conversation}=await admin.from("conversations").select("*")
      .eq("id",conversationId).eq("organization_id",org).maybeSingle();
    if(!conversation) return out({error:"Conversation not found"},404);

    if(action==="resolve"){
      await admin.from("conversations").update({status:"resolved",updated_at:new Date().toISOString()})
        .eq("id",conversationId).eq("organization_id",org);
      return out({ok:true,status:"resolved"});
    }

    if(!await insideReplyWindow(org,conversationId)){
      return out({error:"The latest customer message is outside the 24-hour WhatsApp reply window. Use an approved WhatsApp template before sending a new free-form message."},409);
    }

    const {data:connection}=await admin.from("channel_connections").select("*")
      .eq("id",conversation.channel_connection_id).eq("organization_id",org)
      .eq("channel_type","whatsapp").maybeSingle();
    if(!connection) return out({error:"WhatsApp connection not found"},404);
    const to=String(conversation.external_thread_id||"");
    if(!to) return out({error:"Conversation has no WhatsApp recipient"},400);

    if(action==="catalog"){
      const {data:items}=await admin.from("products_services")
        .select("id,name,description,price,currency,is_orderable,is_bookable,whatsapp_catalog_enabled")
        .eq("organization_id",org).eq("active",true)
        .or("whatsapp_catalog_enabled.eq.true,is_orderable.eq.true,is_bookable.eq.true")
        .order("sort_order").order("name").limit(10);
      if(!items?.length) return out({error:"No WhatsApp-visible products or services are configured."},400);
      const rows=items.map((x:any)=>({
        id:"catalog:"+x.id,
        title:String(x.name).slice(0,24),
        description:String(x.price!=null?((x.currency||"")+" "+Number(x.price).toLocaleString()):x.description||"").slice(0,72)
      }));
      const body="Choose a product or service. You can then ask for a quote, place an order, or book where available.";
      const payload=await sendMeta(connection,to,{
        type:"interactive",
        interactive:{type:"list",body:{text:body},action:{button:"View options",sections:[{title:"Products & services",rows}]}}
      });
      await recordOutbound(org,conversationId,body,payload,"interactive");
      return out({ok:true,type:"catalog",count:rows.length});
    }

    const text=String(b.body||"").trim();
    if(!text) return out({error:"Message body is required"},400);
    const payload=await sendMeta(connection,to,{type:"text",text:{body:text}});
    await recordOutbound(org,conversationId,text,payload,"text");
    return out({ok:true,type:"text"});
  }catch(e){
    return out({error:e instanceof Error?e.message:String(e)},400);
  }
});