'use client';

import React, { useRef, useState, useEffect, Suspense } from 'react';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import { PerspectiveCamera, RoundedBox, Float, Text3D, MeshDistortMaterial, Sphere, Box, Torus, Ring } from '@react-three/drei';
import * as THREE from 'three';
import gsap from 'gsap';
import { motion, AnimatePresence } from 'framer-motion';
import Link from 'next/link';

/* ─── Slide Data ─── */
const SLIDES = [
  {
    id: 'gaming',
    title: 'CHALLENGE\nTHE WORLD',
    sub: 'Real-time quiz battles',
    description: 'Compete in lightning-fast quiz battles, speed math duels, and word challenges against players worldwide. Climb the leaderboard and claim your glory.',
    color: '#8b5cf6',
    accent: '#a78bfa',
    cta: 'PLAY NOW',
    href: '/auth?signup=true',
    tag: '🎮 Gaming',
  },
  {
    id: 'stream',
    title: 'WATCH &\nEARN LIVE',
    sub: 'Interactive live streams',
    description: 'Join thousands of viewers in synchronized live game streams. Vote, predict, and interact with hosts in real time — and win coins while watching.',
    color: '#ec4899',
    accent: '#f472b6',
    cta: 'WATCH LIVE',
    href: '/auth?signup=true',
    tag: '📺 Streaming',
  },
  {
    id: 'market',
    title: 'COLLECT &\nTRADE',
    sub: 'Digital asset marketplace',
    description: 'Buy, sell, and trade exclusive digital items — weapons, avatars, effects, and crowns. Rare drops every weekend. Your collection defines your status.',
    color: '#f59e0b',
    accent: '#fbbf24',
    cta: 'EXPLORE MARKET',
    href: '/auth?signup=true',
    tag: '💎 Marketplace',
  },
  {
    id: 'social',
    title: 'BUILD YOUR\nCREW',
    sub: 'Social gaming community',
    description: 'Share your victories, follow top players, create your own challenges, and build a following. REWIFY is where gaming meets social media.',
    color: '#10b981',
    accent: '#34d399',
    cta: 'JOIN COMMUNITY',
    href: '/auth?signup=true',
    tag: '👥 Social',
  },
];

/* ─── Gaming Scene: floating cubes (game grid) ─── */
function GamingScene({ active }: { active: boolean }) {
  const groupRef = useRef<THREE.Group>(null);
  const cubeRefs = useRef<THREE.Mesh[]>([]);
  const GRID = 4;

  useFrame((state) => {
    if (!groupRef.current) return;
    groupRef.current.rotation.y = state.clock.elapsedTime * 0.3;
    groupRef.current.rotation.x = Math.sin(state.clock.elapsedTime * 0.5) * 0.15;
    cubeRefs.current.forEach((cube, i) => {
      if (!cube) return;
      const col = i % GRID; const row = Math.floor(i / GRID);
      const phase = (col + row) * 0.4;
      cube.position.y = Math.sin(state.clock.elapsedTime * 1.5 + phase) * 0.3;
      cube.rotation.x = state.clock.elapsedTime * 0.5;
      cube.rotation.z = state.clock.elapsedTime * 0.3;
      const mat = cube.material as THREE.MeshStandardMaterial;
      mat.emissiveIntensity = 0.3 + Math.sin(state.clock.elapsedTime * 2 + phase) * 0.2;
    });
  });

  return (
    <group ref={groupRef}>
      {Array.from({ length: GRID * GRID }).map((_, i) => {
        const col = i % GRID; const row = Math.floor(i / GRID);
        const x = (col - GRID / 2 + 0.5) * 1.1;
        const z = (row - GRID / 2 + 0.5) * 1.1;
        const highlight = (col + row) % 3 === 0;
        return (
          <mesh key={i} position={[x, 0, z]} ref={(el) => { if (el) cubeRefs.current[i] = el; }}>
            <boxGeometry args={[0.8, 0.8, 0.8]} />
            <meshStandardMaterial
              color={highlight ? '#8b5cf6' : '#1e1b4b'}
              emissive={highlight ? '#8b5cf6' : '#3730a3'}
              emissiveIntensity={0.4}
              roughness={0.2}
              metalness={0.8}
            />
          </mesh>
        );
      })}
    </group>
  );
}

/* ─── Streaming Scene: waveform bars + orbit ring ─── */
function StreamScene({ active }: { active: boolean }) {
  const groupRef = useRef<THREE.Group>(null);
  const barsRef = useRef<THREE.Mesh[]>([]);
  const BAR_COUNT = 24;

  useFrame((state) => {
    if (!groupRef.current) return;
    groupRef.current.rotation.y = state.clock.elapsedTime * 0.2;
    barsRef.current.forEach((bar, i) => {
      if (!bar) return;
      const h = 0.3 + Math.abs(Math.sin(state.clock.elapsedTime * 3 + i * 0.35)) * 2.5;
      bar.scale.y = h;
      bar.position.y = h / 2;
      const mat = bar.material as THREE.MeshStandardMaterial;
      mat.emissiveIntensity = 0.2 + Math.abs(Math.sin(state.clock.elapsedTime * 3 + i * 0.35)) * 0.8;
    });
  });

  return (
    <group ref={groupRef}>
      {/* Orbit ring */}
      <Torus args={[3.5, 0.03, 8, 80]} rotation={[Math.PI / 2, 0, 0]}>
        <meshStandardMaterial color="#ec4899" emissive="#ec4899" emissiveIntensity={0.6} transparent opacity={0.4} />
      </Torus>
      {/* Waveform bars */}
      {Array.from({ length: BAR_COUNT }).map((_, i) => {
        const angle = (i / BAR_COUNT) * Math.PI * 2;
        const r = 2;
        return (
          <mesh key={i} position={[Math.cos(angle) * r, 0, Math.sin(angle) * r]}
            ref={(el) => { if (el) barsRef.current[i] = el; }}>
            <boxGeometry args={[0.12, 1, 0.12]} />
            <meshStandardMaterial color="#ec4899" emissive="#ec4899" emissiveIntensity={0.5} />
          </mesh>
        );
      })}
      {/* Center sphere */}
      <Float speed={2}>
        <Sphere args={[0.6, 32, 32]}>
          <MeshDistortMaterial color="#f472b6" speed={3} distort={0.4} emissive="#ec4899" emissiveIntensity={0.5} />
        </Sphere>
      </Float>
    </group>
  );
}

/* ─── Marketplace Scene: floating coins & gems ─── */
function MarketScene({ active }: { active: boolean }) {
  const groupRef = useRef<THREE.Group>(null);
  const ITEMS = 12;

  useFrame((state) => {
    if (!groupRef.current) return;
    groupRef.current.rotation.y = state.clock.elapsedTime * 0.25;
    groupRef.current.children.forEach((child, i) => {
      child.position.y = Math.sin(state.clock.elapsedTime * 1.2 + i * 0.6) * 0.5;
      child.rotation.x = state.clock.elapsedTime * 0.8;
      child.rotation.z = state.clock.elapsedTime * 0.4;
    });
  });

  const COLORS = ['#f59e0b', '#fbbf24', '#fcd34d', '#f97316', '#ef4444'];

  return (
    <group ref={groupRef}>
      {Array.from({ length: ITEMS }).map((_, i) => {
        const angle = (i / ITEMS) * Math.PI * 2;
        const radius = 1.5 + (i % 3) * 0.8;
        const color = COLORS[i % COLORS.length];
        const isCoin = i % 3 !== 2;
        return (
          <mesh key={i} position={[Math.cos(angle) * radius, (i % 4) * 0.5 - 1, Math.sin(angle) * radius]}>
            {isCoin
              ? <cylinderGeometry args={[0.3, 0.3, 0.08, 32]} />
              : <octahedronGeometry args={[0.25]} />
            }
            <meshStandardMaterial color={color} emissive={color} emissiveIntensity={0.5} metalness={0.9} roughness={0.1} />
          </mesh>
        );
      })}
    </group>
  );
}

/* ─── Social Scene: network nodes ─── */
function SocialScene({ active }: { active: boolean }) {
  const groupRef = useRef<THREE.Group>(null);
  const NODES = 10;

  useFrame((state) => {
    if (!groupRef.current) return;
    groupRef.current.rotation.y = state.clock.elapsedTime * 0.2;
    groupRef.current.rotation.x = Math.sin(state.clock.elapsedTime * 0.4) * 0.2;
    groupRef.current.children.forEach((child, i) => {
      child.scale.setScalar(1 + Math.sin(state.clock.elapsedTime * 2 + i) * 0.15);
    });
  });

  const nodes = Array.from({ length: NODES }).map((_, i) => {
    const theta = Math.acos(1 - (2 * (i + 0.5)) / NODES);
    const phi = Math.PI * (1 + Math.sqrt(5)) * i;
    return new THREE.Vector3(
      2.5 * Math.sin(theta) * Math.cos(phi),
      2.5 * Math.cos(theta),
      2.5 * Math.sin(theta) * Math.sin(phi),
    );
  });

  return (
    <group ref={groupRef}>
      {nodes.map((pos, i) => (
        <group key={i}>
          <Sphere args={[0.2 + (i % 3) * 0.1, 16, 16]} position={[pos.x, pos.y, pos.z]}>
            <meshStandardMaterial color="#10b981" emissive="#10b981" emissiveIntensity={0.6} />
          </Sphere>
          {/* Line to center */}
          <line>
            <bufferGeometry>
              <bufferAttribute
                attach="attributes-position"
                args={[new Float32Array([0, 0, 0, pos.x, pos.y, pos.z]), 3]}
              />
            </bufferGeometry>
            <lineBasicMaterial color="#10b981" transparent opacity={0.3} />
          </line>
        </group>
      ))}
      <Float speed={2}>
        <Sphere args={[0.4, 32, 32]}>
          <meshStandardMaterial color="#34d399" emissive="#10b981" emissiveIntensity={0.8} />
        </Sphere>
      </Float>
    </group>
  );
}

const SCENE_COMPONENTS = [GamingScene, StreamScene, MarketScene, SocialScene];

/* ─── Particle Field ─── */
function Particles({ color }: { color: string }) {
  const ref = useRef<THREE.Points>(null);
  const COUNT = 120;
  const positions = React.useMemo(() => {
    const arr = new Float32Array(COUNT * 3);
    for (let i = 0; i < COUNT; i++) {
      arr[i * 3] = (Math.random() - 0.5) * 20;
      arr[i * 3 + 1] = (Math.random() - 0.5) * 20;
      arr[i * 3 + 2] = (Math.random() - 0.5) * 20;
    }
    return arr;
  }, []);

  useFrame((state) => {
    if (ref.current) {
      ref.current.rotation.y = state.clock.elapsedTime * 0.04;
      ref.current.rotation.x = state.clock.elapsedTime * 0.02;
    }
  });

  return (
    <points ref={ref}>
      <bufferGeometry>
        <bufferAttribute attach="attributes-position" args={[positions, 3]} />
      </bufferGeometry>
      <pointsMaterial size={0.06} color={color} transparent opacity={0.6} sizeAttenuation />
    </points>
  );
}

/* ─── Active Scene ─── */
function ActiveScene({ slideIndex, color }: { slideIndex: number, color: string }) {
  const SceneComponent = SCENE_COMPONENTS[slideIndex];
  return (
    <>
      <SceneComponent active />
      <Particles color={color} />
    </>
  );
}

/* ─── Main Export ─── */
export default function ThreeCarousel() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [mounted, setMounted] = useState(false);
  const slide = SLIDES[activeIndex];

  useEffect(() => { setMounted(true); }, []);

  const go = (dir: 1 | -1) => {
    if (isTransitioning) return;
    setIsTransitioning(true);
    setActiveIndex((p) => (p + dir + SLIDES.length) % SLIDES.length);
    setTimeout(() => setIsTransitioning(false), 800);
  };

  if (!mounted) return <div className="w-full h-screen bg-black" />;

  return (
    <div className="relative w-full h-screen bg-black overflow-hidden font-sans select-none">
      {/* Three.js Canvas */}
      <div className="absolute inset-0 z-0">
        <Canvas
          gl={{ antialias: true, powerPreference: 'high-performance' }}
          dpr={[1, 2]}
        >
          <PerspectiveCamera makeDefault position={[0, 0, 8]} fov={55} />
          <ambientLight intensity={0.3} />
          <pointLight position={[10, 10, 10]} intensity={2} color={slide.color} />
          <pointLight position={[-10, -8, -6]} intensity={1} color={slide.accent} />
          <Suspense fallback={null}>
            <AnimatedActiveScene slideIndex={activeIndex} color={slide.color} />
          </Suspense>
        </Canvas>
      </div>

      {/* Nav Bar */}
      <header className="absolute top-0 left-0 right-0 z-20 flex items-center justify-between px-8 md:px-16 py-8">
        <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} className="flex items-center gap-2.5">
          <div className="w-8 h-8 bg-white rounded-xl flex items-center justify-center">
            <div className="w-4 h-4 bg-black rounded-md" />
          </div>
          <span className="text-white font-black tracking-tighter text-xl">REWIFY</span>
        </motion.div>

        <nav className="hidden md:flex items-center gap-10">
          {['GAMES', 'STREAMS', 'MARKET', 'SOCIAL'].map((label, i) => (
            <motion.button
              key={label}
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.06 }}
              onClick={() => setActiveIndex(i)}
              className={`text-[11px] font-black tracking-[0.25em] transition-colors ${
                activeIndex === i ? 'text-white' : 'text-zinc-500 hover:text-zinc-300'
              }`}
            >
              {label}
            </motion.button>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          <Link href="/auth">
            <button className="text-sm font-black text-zinc-400 hover:text-white transition-colors hidden sm:block">LOG IN</button>
          </Link>
          <Link href="/auth?signup=true">
            <button className="px-5 py-2.5 bg-white text-black font-black rounded-full text-sm hover:bg-zinc-100 transition-all">SIGN UP</button>
          </Link>
        </div>
      </header>

      {/* Hero Text */}
      <div className="absolute inset-0 z-10 flex flex-col justify-end pb-24 px-8 md:px-16 pointer-events-none">
        {/* Tag */}
        <AnimatePresence mode="wait">
          <motion.div
            key={`tag-${activeIndex}`}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.5 }}
            className="mb-5"
          >
            <span className="text-[11px] font-black tracking-[0.3em] uppercase px-4 py-1.5 rounded-full border"
              style={{ color: slide.accent, borderColor: slide.color + '44', backgroundColor: slide.color + '18' }}>
              {slide.tag}
            </span>
          </motion.div>
        </AnimatePresence>

        {/* Title */}
        <AnimatePresence mode="wait">
          <motion.h1
            key={`title-${activeIndex}`}
            initial={{ opacity: 0, y: 40, filter: 'blur(12px)' }}
            animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
            exit={{ opacity: 0, y: -30, filter: 'blur(12px)' }}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="text-white font-black tracking-tighter leading-[0.85] mb-5"
            style={{ fontSize: 'clamp(3rem, 8vw, 7rem)', whiteSpace: 'pre-line' }}
          >
            {slide.title}
          </motion.h1>
        </AnimatePresence>

        {/* Description + CTA */}
        <div className="flex flex-col md:flex-row items-start md:items-end gap-6 md:gap-16">
          <AnimatePresence mode="wait">
            <motion.p
              key={`desc-${activeIndex}`}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ delay: 0.2, duration: 0.6 }}
              className="text-zinc-400 text-base md:text-lg max-w-md leading-relaxed pointer-events-auto"
            >
              {slide.description}
            </motion.p>
          </AnimatePresence>

          <AnimatePresence mode="wait">
            <motion.div
              key={`cta-${activeIndex}`}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              transition={{ delay: 0.3 }}
              className="flex items-center gap-4 flex-shrink-0 pointer-events-auto"
            >
              <Link href={slide.href}>
                <button
                  className="px-10 py-5 font-black rounded-full text-black text-sm transition-all hover:scale-105 active:scale-95"
                  style={{ backgroundColor: slide.accent }}
                >
                  {slide.cta}
                </button>
              </Link>
              <Link href="/auth">
                <button className="px-10 py-5 border border-white/15 text-white font-black rounded-full text-sm hover:bg-white/5 transition-all">
                  LOG IN
                </button>
              </Link>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Bottom bar */}
        <div className="flex items-center justify-between mt-10 pointer-events-auto">
          <div className="flex items-center gap-4">
            {SLIDES.map((s, i) => (
              <button
                key={i}
                onClick={() => setActiveIndex(i)}
                className="h-1 rounded-full transition-all duration-700"
                style={{
                  width: i === activeIndex ? '4rem' : '1.25rem',
                  backgroundColor: i === activeIndex ? slide.accent : 'rgba(255,255,255,0.15)',
                }}
              />
            ))}
            <span className="text-zinc-600 text-xs font-black ml-2">
              0{activeIndex + 1} <span className="text-zinc-700">/</span> 0{SLIDES.length}
            </span>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => go(-1)}
              className="w-11 h-11 rounded-full border border-white/10 flex items-center justify-center text-white hover:bg-white/10 transition-all active:scale-95 backdrop-blur-sm"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
            </button>
            <button
              onClick={() => go(1)}
              className="w-11 h-11 rounded-full border border-white/10 flex items-center justify-center text-white hover:bg-white/10 transition-all active:scale-95 backdrop-blur-sm"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="m9 18 6-6-6-6"/></svg>
            </button>
          </div>
        </div>
      </div>

      {/* Radial glow */}
      <div
        className="absolute inset-0 -z-10 transition-all duration-1000 pointer-events-none"
        style={{ background: `radial-gradient(ellipse 60% 50% at 70% 50%, ${slide.color}18 0%, transparent 70%)` }}
      />
      <div
        className="absolute inset-0 -z-10 transition-all duration-1000 pointer-events-none"
        style={{ background: `radial-gradient(ellipse 40% 40% at 20% 80%, ${slide.color}10 0%, transparent 60%)` }}
      />
    </div>
  );
}

/* Wrapper to remount scene on slide change */
function AnimatedActiveScene({ slideIndex, color }: { slideIndex: number; color: string }) {
  return <ActiveScene slideIndex={slideIndex} color={color} />;
}
