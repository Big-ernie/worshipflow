import { createClient, SupabaseAuthAdapter } from "https://esm.sh/@neondatabase/neon-js@0.7.0-beta";
const client=createClient({
  auth:{url:"https://ep-flat-water-b9kwqwj5.neonauth.c-7.eu-central-1.aws.neon.tech/crmhub_dev/auth",adapter:SupabaseAuthAdapter()},
  dataApi:{url:"https://ep-flat-water-b9kwqwj5.apirest.c-7.eu-central-1.aws.neon.tech/crmhub_dev/rest/v1"}
});
const db=client.schema("crm_stage");
const $=id=>document.getElementById(id);
const S={user:null,org:null,orgs:[],deals:[],contacts:[],busy:false,signup:false};
const stages=["New Enquiry","Requirements Confirmed","Quote Sent","Follow-up Due","Negotiation","Won","Lost"];
const esc=x=>String(x??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const gh=v=>"GH₵"+Number(v||0).toLocaleString("en-GH",{maximumFractionDigits:2});
function report(message,error=true,box=S.user?"appError":"authError"){
 const el=$(box);el.textContent=message||"Request failed.";el.className=error?"errorBox":"successBox";el.classList.remove("hidden");
}
function clearReport(){for(const id of ["authError","appError","appSuccess"])$(id).classList.add("hidden")}
function busy(id,state){const b=$(id);if(!b)return;b.disabled=state;if(!b.dataset.defaultText)b.dataset.defaultText=b.textContent;b.textContent=state?"Working…":b.dataset.defaultText;}
function loginView(){S.user=null;S.org=null;S.orgs=[];$("appView").classList.add("hidden");$("loginView").classList.remove("hidden");clearReport();}
function appView(){$("loginView").classList.add("hidden");$("appView").classList.remove("hidden");}
function setMode(signup){S.signup=signup;$("tabSignup").classList.toggle("active",signup);$("tabLogin").classList.toggle("active",!signup);$("nameField").classList.toggle("hidden",!signup);$("fullName").required=signup;$("submitAuth").dataset.defaultText=signup?"Create test account":"Sign in to preview";$("submitAuth").textContent=$("submitAuth").dataset.defaultText;$("password").autocomplete=signup?"new-password":"current-password";clearReport();}
$("tabSignup").addEventListener("click",()=>setMode(true));
$("tabLogin").addEventListener("click",()=>setMode(false));
$("authForm").addEventListener("submit",async e=>{
 e.preventDefault();clearReport();busy("submitAuth",true);
 try{
  const email=$("email").value.trim(),password=$("password").value;
  const result=S.signup?
   await client.auth.signUp({email,password,options:{data:{name:$("fullName").value.trim()}}}):
   await client.auth.signInWithPassword({email,password});
  if(result.error)throw new Error(result.error.message||"Sign-in failed");
  const session=await client.auth.getSession();
  if(session.error)throw new Error(session.error.message||"Unable to access session");
  if(!session.data?.session){
   setMode(false);report("Please complete any email verification, then sign in.",false);return;
  }
  await initialize($("fullName").value.trim());
 }catch(err){report(err?.message||"Authentication failed");}
 finally{busy("submitAuth",false);}
});
$("signout").addEventListener("click",async()=>{
 try{const out=await client.auth.signOut();if(out.error)throw out.error;loginView();}
 catch(err){report("Could not sign out: "+(err?.message||"Unknown error"));}
});
$("refresh").addEventListener("click",async()=>{clearReport();try{await loadSpaces(true)}catch(err){report(err.message)}});
$("showWorkspaceForm").addEventListener("click",()=>$("createWorkspaceArea").classList.toggle("hidden"));
$("workspaceSelect").addEventListener("change",async()=>{
 S.org=S.orgs.find(x=>x.id===$("workspaceSelect").value)||null;
 try{await loadWorkspace()}catch(err){report(err.message);}
});
$("workspaceForm").addEventListener("submit",async e=>{
 e.preventDefault();clearReport();busy("submitWorkspace",true);
 try{
  const res=await db.rpc("preview_create_workspace",{
   p_name:$("wsName").value.trim(),p_industry:$("wsIndustry").value.trim()||null,p_business_template:$("wsTemplate").value
  });
  if(res.error)throw res.error;
  $("workspaceForm").reset();$("createWorkspaceArea").classList.add("hidden");
  await loadSpaces(true,res.data);
  report("Test company workspace created.",false,"appSuccess");
 }catch(err){report(err?.message||"Workspace creation failed");}
 finally{busy("submitWorkspace",false);}
});
$("dealForm").addEventListener("submit",async e=>{
 e.preventDefault();clearReport();busy("submitDeal",true);
 try{
  if(!S.org)throw new Error("Select a test workspace");
  const value=Number($("dealAmount").value);
  if(!Number.isFinite(value)||value<0||value>1e12)throw new Error("Enter a valid amount");
  const res=await db.from("deals").insert({
   organization_id:S.org.id,title:$("dealTitle").value.trim(),stage:"New Enquiry",
   amount:value,currency:"GHS",next_action:$("dealNext").value.trim()||null
  }).select("id").single();
  if(res.error)throw res.error;
  $("dealForm").reset();$("dealAmount").value="0";
  await loadWorkspace();report("Sample opportunity created.",false,"appSuccess");
 }catch(err){report(err?.message||"Could not create opportunity");}
 finally{busy("submitDeal",false);}
});
$("contactForm").addEventListener("submit",async e=>{
 e.preventDefault();clearReport();busy("submitContact",true);
 try{
  if(!S.org)throw new Error("Select a test workspace");
  const res=await db.from("contacts").insert({
   organization_id:S.org.id,first_name:$("contactFirst").value.trim(),
   last_name:$("contactLast").value.trim()||null,email:$("contactEmail").value.trim()||null,
   phone:$("contactPhone").value.trim()||null
  }).select("id").single();
  if(res.error)throw res.error;
  $("contactForm").reset();await loadWorkspace();
  report("Sample contact created.",false,"appSuccess");
 }catch(err){report(err?.message||"Could not create contact");}
 finally{busy("submitContact",false);}
});
async function changeStage(id,stage){
 if(!S.org||!stages.includes(stage))return;
 const res=await db.from("deals").update({stage}).eq("id",id).eq("organization_id",S.org.id).select("id");
 if(res.error)throw res.error;
 await loadWorkspace();
}
async function removeRecord(table,id){
 if(!S.org||!["deals","contacts"].includes(table))return;
 if(!window.confirm("Remove this sample record?"))return;
 const res=await db.from(table).delete().eq("id",id).eq("organization_id",S.org.id);
 if(res.error)throw res.error;
 await loadWorkspace();
}
$("dealRows").addEventListener("change",e=>{
 const select=e.target.closest("select[data-stage]");
 if(select)changeStage(select.dataset.stage,select.value).catch(err=>report(err.message));
});
for(const id of ["dealRows","contactRows"])$(id).addEventListener("click",e=>{
 const b=e.target.closest("button[data-delete]");
 if(b)removeRecord(b.dataset.delete,b.dataset.id).catch(err=>report(err.message));
});
async function initialize(name=""){
 if(S.busy)return;S.busy=true;clearReport();
 try{
  const response=await client.auth.getSession();
  if(response.error)throw response.error;
  const session=response.data?.session,user=response.data?.user||session?.user;
  if(!session||!user){loginView();return;}
  S.user=user;$("userEmail").textContent=user.email||"Test account";appView();
  const profile=await db.rpc("preview_bootstrap_profile",{p_full_name:name||user.name||user.user_metadata?.name||null});
  if(profile.error)throw new Error("Failed to prepare test profile: "+profile.error.message);
  await loadSpaces(true);
 }catch(err){report(err?.message||"Cannot load preview CRM");}
 finally{S.busy=false;}
}
async function loadSpaces(preserve=false,chooseId=null){
 const r=await db.from("organizations").select("id,name,industry,currency,created_at").order("created_at",{ascending:true});
 if(r.error)throw new Error("Workspaces unavailable: "+r.error.message);
 S.orgs=r.data||[];
 const old=preserve?S.org?.id:null;
 S.org=S.orgs.find(x=>x.id===chooseId)||S.orgs.find(x=>x.id===old)||S.orgs[0]||null;
 $("workspaceSelect").innerHTML=S.orgs.map(x=>'<option value="'+esc(x.id)+'">'+esc(x.name)+'</option>').join("");
 $("workspaceSelect").disabled=!S.org;
 if(S.org)$("workspaceSelect").value=S.org.id;
 $("workspaceEmpty").classList.toggle("hidden",S.orgs.length>0);
 $("workspaceData").classList.toggle("hidden",S.orgs.length===0);
 if(S.org)await loadWorkspace();
}
async function loadWorkspace(){
 if(!S.org)return;
 const org=S.org.id;
 const [deals,contacts]=await Promise.all([
  db.from("deals").select("id,title,amount,stage,next_action").eq("organization_id",org).order("created_at",{ascending:false}),
  db.from("contacts").select("id,first_name,last_name,email,phone").eq("organization_id",org).order("created_at",{ascending:false})
 ]);
 if(deals.error||contacts.error)throw new Error("Data access denied: "+(deals.error?.message||contacts.error?.message));
 if(!S.org||org!==S.org.id)return;
 S.deals=deals.data||[];S.contacts=contacts.data||[];
 const open=S.deals.filter(d=>!["Won","Lost"].includes(d.stage));
 $("kpiOpen").textContent=open.length;
 $("kpiValue").textContent=gh(open.reduce((a,d)=>a+Number(d.amount||0),0));
 $("kpiContacts").textContent=S.contacts.length;
 $("dealCount").textContent=S.deals.length+" deals";
 $("contactCount").textContent=S.contacts.length+" contacts";
 $("emptyDeals").classList.toggle("hidden",S.deals.length>0);
 $("emptyContacts").classList.toggle("hidden",S.contacts.length>0);
 $("dealRows").innerHTML=S.deals.map(d=>'<tr><td><b>'+esc(d.title)+'</b><br><span class="muted">'+esc(d.next_action||"")+'</span></td><td>'+gh(d.amount)+'</td><td><select class="input" style="min-width:135px;padding:7px" data-stage="'+esc(d.id)+'">'+stages.map(st=>'<option value="'+esc(st)+'" '+(st===d.stage?"selected":"")+'>'+esc(st)+'</option>').join("")+'</select></td><td><button class="btn danger" data-delete="deals" data-id="'+esc(d.id)+'">Remove</button></td></tr>').join("");
 $("contactRows").innerHTML=S.contacts.map(c=>'<tr><td><b>'+esc([c.first_name,c.last_name].filter(Boolean).join(" "))+'</b></td><td>'+esc(c.email||"")+'</td><td>'+esc(c.phone||"")+'</td><td><button class="btn danger" data-delete="contacts" data-id="'+esc(c.id)+'">Remove</button></td></tr>').join("");
}
client.auth.onAuthStateChange?.((event)=>{if(event==="SIGNED_OUT")loginView();});
void initialize();
