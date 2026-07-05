export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Deliberately minimal for now. Middleware already protects everything
  // outside /login, /signup, /callback — this route group exists so the
  // real sidebar/bottom-nav shell (Phase 10.1) has somewhere to go
  // without restructuring routes later.
  return <div className="min-h-screen bg-background">{children}</div>;
}