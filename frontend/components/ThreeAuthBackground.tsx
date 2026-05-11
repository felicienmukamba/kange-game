'use client';

import React, { useRef } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Float, Sphere, MeshDistortMaterial, PerspectiveCamera } from '@react-three/drei';
import * as THREE from 'three';

function AnimatedShapes() {
  const sphereRef = useRef<THREE.Mesh>(null);

  useFrame((state) => {
    if (!sphereRef.current) return;
    sphereRef.current.rotation.x = state.clock.getElapsedTime() * 0.2;
    sphereRef.current.rotation.y = state.clock.getElapsedTime() * 0.3;
  });

  return (
    <group>
      <Float speed={2} rotationIntensity={1} floatIntensity={2}>
        <Sphere ref={sphereRef} args={[1, 64, 64]} position={[-2, 0, 0]}>
          <MeshDistortMaterial
            color="#4f46e5"
            speed={3}
            distort={0.4}
            radius={1}
          />
        </Sphere>
      </Float>
      <Float speed={3} rotationIntensity={2} floatIntensity={1}>
        <Sphere args={[0.5, 32, 32]} position={[2, 1, -2]}>
          <MeshDistortMaterial
            color="#9333ea"
            speed={5}
            distort={0.6}
            radius={1}
          />
        </Sphere>
      </Float>
    </group>
  );
}

export default function ThreeAuthBackground() {
  return (
    <div className="absolute inset-0 -z-10 bg-black">
      <Canvas>
        <PerspectiveCamera makeDefault position={[0, 0, 5]} />
        <ambientLight intensity={0.5} />
        <pointLight position={[10, 10, 10]} intensity={1} />
        <spotLight position={[-10, 10, 10]} angle={0.15} penumbra={1} intensity={1} />
        <AnimatedShapes />
      </Canvas>
    </div>
  );
}
