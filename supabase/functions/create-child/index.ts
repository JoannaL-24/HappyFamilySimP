import { createClient } from "supabase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { childName, childEmail, loginCode } = await req.json();

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: authUser, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email: childEmail,
        password: loginCode,
        email_confirm: true,
        user_metadata: { role: "child" },
      });

    if (authError) throw authError;

    const childId = authUser.user.id;

    const { error: profileError } = await supabaseAdmin
      .from("profiles")
      .insert({
        id: childId,
        name: childName,
        role: "child",
        login_code: loginCode,
        parent_email: childEmail,
        avatar_path: "system/default_avatar.png",
      });

    if (profileError) throw profileError;

    return new Response(JSON.stringify({ success: true, childId: childId }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
