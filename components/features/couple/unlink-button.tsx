"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { unlinkCouple } from "@/app/actions/couples";
import { Button } from "@/components/ui/button";

export function UnlinkButton({ coupleId }: { coupleId: string }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const handleUnlink = async () => {
    if (!confirm("Unlink from your partner? This can be undone by inviting again.")) return;
    setLoading(true);
    await unlinkCouple(coupleId);
    router.refresh();
    setLoading(false);
  };

  return (
    <Button variant="outline" onClick={handleUnlink} disabled={loading}>
      {loading ? "Unlinking…" : "Unlink"}
    </Button>
  );
}