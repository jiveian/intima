import type { Metadata } from "next";
import { Fraunces, Inter } from "next/font/google";
import { assertEnv } from "@/lib/env";        {/* ← new line */}
import "./globals.css";

assertEnv();                                   {/* ← new line */}

// Fraunces — our wordmark/display font. We only need weight 500
// (the one weight we approved for the logo), so we're not loading
// unused weights the browser would have to download for nothing.
const fraunces = Fraunces({
  variable: "--font-fraunces",
  subsets: ["latin"],
  weight: ["500"],
});

// Inter — our body/UI font. Loading a small range of weights since
// forms, buttons, and body text each need slightly different weight
// (regular for body copy, medium for labels/buttons).
const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

export const metadata: Metadata = {
  title: "Intima",
  description: "A natural cycle-awareness and relationship wellbeing app for couples",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${fraunces.variable} ${inter.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}