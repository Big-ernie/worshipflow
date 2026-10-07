
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

Deno.serve(async(req)=>{
  const out=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:responseHeaders(req)});
  if(req.method==="OPTIONS")return new Response("ok",{headers:responseHeaders(req)});
  if(req.method!=="POST")return out({error:"Method not allowed"},405);
  try{
    const jwt=(req.headers.get("authorization")||"").replace(/^Bearer\s+/i,"");
    const {data:u,error:ue}=await admin.auth.getUser(jwt);
    if(ue||!u.user)return out({error:"Invalid session"},401);

    const b=await req.json();
    const action=String(b.action||"");

    if(action==="create"){
      const name=String(b.name||"").trim();
      if(name.length<2)return out({error:"Workspace name is required"},400);
      const {data,error}=await admin.rpc("create_workspace_template_server",{
        p_user:u.user.id,
        p_name:name,
        p_slug:b.slug||null,
        p_industry:b.industry||null,
        p_currency:b.currency||"GHS",
        p_timezone:b.timezone||"Africa/Accra",
        p_business_template:String(b.business_template||"general")
      });
      if(error)throw error;
      return out({ok:true,organization_id:data});
    }

    if(action==="accept_invite"){
      const token=String(b.token||"").trim();
      if(!token)return out({error:"Invite token is required"},400);
      const {data,error}=await admin.rpc("accept_workspace_invite_server",{p_user:u.user.id,p_token:token});
      if(error)throw error;
      return out({ok:true,organization_id:data});
    }

    return out({error:"Unknown action"},400);
  }catch(e){return out({error:e instanceof Error?e.message:String(e)},400)}
});
