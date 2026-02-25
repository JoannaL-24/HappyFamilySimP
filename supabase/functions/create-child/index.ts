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

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  let childId: string | null = null;

  try {
    const { childName, childEmail, sixDigitCode, role, avatarPath, parentId } =
      await req.json();

    const { data: authUser, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email: childEmail,
        password: sixDigitCode,
        email_confirm: true,
      });

    if (authError) throw authError;

    childId = authUser.user.id;

    const { error: profileError } = await supabaseAdmin
      .from("profiles")
      .insert({
        id: childId,
        name: childName,
        role: role,
        avatar_path: avatarPath,
        code: sixDigitCode,
      });

    if (profileError) throw profileError;

    const { error: linkError } = await supabaseAdmin
      .from("family_links")
      .insert({
        parent_id: parentId,
        child_id: childId,
      });

    if (linkError) throw linkError;

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    // rollback
    if (childId) {
      await supabaseAdmin.auth.admin.deleteUser(childId);
    }

    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
