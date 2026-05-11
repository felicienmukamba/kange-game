'use client';

import React, { useRef, useState, useMemo, useEffect, Suspense } from 'react';
import { Canvas, useFrame, useLoader } from '@react-three/fiber';
import { Float, PerspectiveCamera, Text, MeshDistortMaterial, Environment, ContactShadows, RoundedBox } from '@react-three/drei';
import * as THREE from 'three';
import gsap from 'gsap';
import { motion, AnimatePresence } from 'framer-motion';

const CAROUSEL_ITEMS = [
  {
    title: 'IMMERSIVE GAMING',
    description: 'Experience the next level of social gaming with real-time challenges and high-stakes rewards.',
    image: '/images/gaming.png',
    color: '#8b5cf6',
  },
  {
    title: 'LIVE STREAMING',
    description: 'Connect with your audience like never before in interactive streams with glassmorphism UI.',
    image: '/images/streaming.png',
    color: '#ec4899',
  },
  {
    title: 'DIGITAL MARKET',
    description: 'Trade, collect, and showcase your digital assets in our premium luxury marketplace.',
    image: '/images/marketplace.png',
    color: '#3b82f6',
  },
];

function CarouselItem({ item, index, activeIndex, totalItems }: { item: any, index: number, activeIndex: number, totalItems: number }) {
  const meshRef = useRef<THREE.Group>(null);
  const texture = useLoader(THREE.TextureLoader, item.image);

  useFrame((state) => {
    if (!meshRef.current) return;
    
    // Calculate position in circle
    const angle = (index - activeIndex) * (Math.PI * 2 / totalItems);
    const radius = 5;
    
    const x = Math.sin(angle) * radius;
    const z = Math.cos(angle) * radius;
    
    // Smoothly transition position
    meshRef.current.position.x = THREE.MathUtils.lerp(meshRef.current.position.x, x, 0.05);
    meshRef.current.position.z = THREE.MathUtils.lerp(meshRef.current.position.z, z, 0.05);
    
    // Face the center
    meshRef.current.lookAt(0, 0, 0);
    
    // Scale up if active
    const scale = index === activeIndex ? 1.2 : 0.8;
    meshRef.current.scale.setScalar(THREE.MathUtils.lerp(meshRef.current.scale.x, scale, 0.1));
    
    // Subtle float animation
    meshRef.current.position.y = Math.sin(state.clock.elapsedTime + index) * 0.1;
  });

  return (
    <group ref={meshRef}>
      <RoundedBox args={[3, 4, 0.1]} radius={0.1} smoothness={4}>
        <meshStandardMaterial map={texture} toneMapped={false} />
      </RoundedBox>
      <mesh position={[0, 0, -0.06]}>
        <boxGeometry args={[3.1, 4.1, 0.05]} />
        <meshStandardMaterial color={item.color} emissive={item.color} emissiveIntensity={1} transparent opacity={0.4} />
      </mesh>
    </group>
  );
}

function Scene({ activeIndex }: { activeIndex: number }) {
  const groupRef = useRef<THREE.Group>(null);

  useFrame((state) => {
    if (!groupRef.current) return;
    // Mouse parallax
    const x = (state.mouse.x * 0.5);
    const y = (state.mouse.y * 0.5);
    groupRef.current.rotation.y = THREE.MathUtils.lerp(groupRef.current.rotation.y, x * 0.1, 0.1);
    groupRef.current.rotation.x = THREE.MathUtils.lerp(groupRef.current.rotation.x, -y * 0.1, 0.1);
  });

  return (
    <group ref={groupRef}>
      {CAROUSEL_ITEMS.map((item, index) => (
        <CarouselItem 
          key={index} 
          item={item} 
          index={index} 
          activeIndex={activeIndex} 
          totalItems={CAROUSEL_ITEMS.length} 
        />
      ))}
    </group>
  );
}

export default function ThreeCarousel() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const nextSlide = () => {
    if (isTransitioning) return;
    setIsTransitioning(true);
    setActiveIndex((prev) => (prev + 1) % CAROUSEL_ITEMS.length);
    setTimeout(() => setIsTransitioning(false), 800);
  };

  const prevSlide = () => {
    if (isTransitioning) return;
    setIsTransitioning(true);
    setActiveIndex((prev) => (prev - 1 + CAROUSEL_ITEMS.length) % CAROUSEL_ITEMS.length);
    setTimeout(() => setIsTransitioning(false), 800);
  };

  if (!mounted) return <div className="w-full h-screen bg-black" />;

  return (
    <div className="relative w-full h-screen bg-black overflow-hidden font-sans">
      <div className="absolute inset-0 z-0">
        <Canvas shadows gl={{ antialias: true, stencil: false, depth: true, powerPreference: "high-performance" }}>
          <PerspectiveCamera makeDefault position={[0, 0, 12]} fov={40} />
          <ambientLight intensity={0.4} />
          <spotLight position={[10, 10, 10]} angle={0.15} penumbra={1} intensity={2} castShadow />
          <pointLight position={[-10, -10, -10]} intensity={1} color={CAROUSEL_ITEMS[activeIndex].color} />
          
          <Suspense fallback={null}>
            <Scene activeIndex={activeIndex} />
            <ContactShadows position={[0, -3.5, 0]} opacity={0.6} scale={20} blur={2.5} far={4.5} />
            <Environment preset="night" />
          </Suspense>
        </Canvas>
      </div>

      {/* UI Overlay */}
      <div className="absolute inset-0 z-10 flex flex-col justify-between p-8 md:p-16 pointer-events-none">
        <div className="flex justify-between items-center">
          <motion.div 
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            className="flex items-center gap-2"
          >
            <div className="w-8 h-8 bg-white rounded-lg" />
            <span className="text-white text-2xl font-black tracking-tighter">REWIFY</span>
          </motion.div>
          <div className="hidden md:flex gap-12 pointer-events-auto">
            {['GAMES', 'STREAMS', 'MARKET', 'ABOUT'].map((link) => (
              <button key={link} className="text-zinc-500 hover:text-white text-xs font-bold tracking-widest transition-colors">
                {link}
              </button>
            ))}
          </div>
          <div className="flex gap-4 pointer-events-auto">
            <button 
              onClick={prevSlide}
              className="w-12 h-12 rounded-full border border-white/10 flex items-center justify-center text-white hover:bg-white/10 transition-all active:scale-95 backdrop-blur-md"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
            </button>
            <button 
              onClick={nextSlide}
              className="w-12 h-12 rounded-full border border-white/10 flex items-center justify-center text-white hover:bg-white/10 transition-all active:scale-95 backdrop-blur-md"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m9 18 6-6-6-6"/></svg>
            </button>
          </div>
        </div>

        <div className="max-w-4xl">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeIndex}
              initial={{ opacity: 0, y: 40, filter: 'blur(10px)' }}
              animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
              exit={{ opacity: 0, y: -40, filter: 'blur(10px)' }}
              transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
              className="space-y-6"
            >
              <div className="overflow-hidden">
                <motion.h2 
                  className="text-white text-7xl md:text-9xl font-black tracking-tighter leading-[0.85]"
                >
                  {CAROUSEL_ITEMS[activeIndex].title.split(' ').map((word, i) => (
                    <span key={i} className="block">{word}</span>
                  ))}
                </motion.h2>
              </div>
              <motion.p 
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.2 }}
                className="text-zinc-400 text-lg md:text-xl max-w-xl leading-relaxed font-medium"
              >
                {CAROUSEL_ITEMS[activeIndex].description}
              </motion.p>
              <motion.div 
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.3 }}
                className="pt-8 pointer-events-auto flex gap-4"
              >
                <button className="group relative px-10 py-5 bg-white text-black font-bold rounded-full hover:bg-zinc-200 transition-all overflow-hidden">
                  <span className="relative z-10">GET STARTED</span>
                  <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/50 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-1000" />
                </button>
                <button className="px-10 py-5 border border-white/20 text-white font-bold rounded-full hover:bg-white/5 transition-all">
                  WATCH TRAILER
                </button>
              </motion.div>
            </motion.div>
          </AnimatePresence>
        </div>

        <div className="flex items-center gap-6">
          <div className="flex gap-2">
            {CAROUSEL_ITEMS.map((_, i) => (
              <button 
                key={i}
                onClick={() => setActiveIndex(i)}
                className={`h-1.5 transition-all duration-700 pointer-events-auto rounded-full ${i === activeIndex ? 'w-24 bg-white' : 'w-6 bg-white/20 hover:bg-white/40'}`}
              />
            ))}
          </div>
          <span className="text-white/40 text-xs font-black tracking-widest">0{activeIndex + 1} / 0{CAROUSEL_ITEMS.length}</span>
        </div>
      </div>

      {/* Decorative background effects */}
      <div className="absolute inset-0 -z-10 overflow-hidden pointer-events-none">
        <div 
          className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] blur-[150px] rounded-full transition-all duration-1000 opacity-20"
          style={{ backgroundColor: CAROUSEL_ITEMS[activeIndex].color }}
        />
        <div 
          className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] blur-[150px] rounded-full transition-all duration-1000 opacity-20"
          style={{ backgroundColor: CAROUSEL_ITEMS[(activeIndex + 1) % CAROUSEL_ITEMS.length].color }}
        />
      </div>
    </div>
  );
}

