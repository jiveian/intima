export function AuthLayout({
  title,
  subtitle,
  children,
}: {
  title: React.ReactNode;
  subtitle: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen">
      {/* Left panel — brand, desktop only. Same shell for every auth page. */}
      <div className="hidden lg:flex lg:w-[42%] flex-col justify-between bg-navy px-12 py-16 text-background">
        <span className="font-display text-lg tracking-tight">INTIMA</span>

        <div>
          <h2 className="font-display text-4xl leading-tight">{title}</h2>
          <p className="mt-4 max-w-sm text-background/60">{subtitle}</p>
        </div>

        <p className="text-xs text-background/40">
          A natural cycle-awareness and relationship wellbeing app for
          couples.
        </p>
      </div>

      {/* Right panel — the actual page content */}
      <div className="flex flex-1 items-center justify-center px-6 py-12">
        <div className="w-full max-w-[400px]">{children}</div>
      </div>
    </div>
  );
}