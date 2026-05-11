import type { Metadata } from "next";
import { Inter, Outfit } from "next/font/google";
import "./globals.css";
import { Toaster } from "sonner";
import { GlobalErrorBoundary } from "./components/GlobalErrorBoundary";

const inter = Inter({
  variable: "--font-sans",
  subsets: ["latin"],
});

const outfit = Outfit({
  variable: "--font-heading",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "REWIFY | Social + Gaming + Live",
  description: "The ultimate platform for interactive live streaming and synchronized gaming.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${outfit.variable} dark h-full antialiased`}
      style={{ colorScheme: "dark" }}
    >
      <body className={`${inter.variable} ${outfit.variable} antialiased dark`}>
        <GlobalErrorBoundary>
          {children}
          <Toaster position="top-right" expand={true} richColors />
        </GlobalErrorBoundary>
      </body>
    </html>
  );
}
