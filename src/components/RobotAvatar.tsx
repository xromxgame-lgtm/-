import React from 'react';
import { AvatarConfig } from '../types';

interface RobotAvatarProps {
  config: AvatarConfig;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  isTalking?: boolean;
  className?: string;
}

export const RobotAvatar: React.FC<RobotAvatarProps> = ({
  config,
  size = 'md',
  isTalking = false,
  className = '',
}) => {
  const sizeClasses = {
    sm: 'w-16 h-16',
    md: 'w-28 h-28',
    lg: 'w-40 h-40',
    xl: 'w-56 h-56',
  }[size];

  const bodyColor = config.bodyColor || '#06b6d4';

  const auraGlowMap: Record<string, string> = {
    purple: 'drop-shadow-[0_0_15px_rgba(168,85,247,0.8)]',
    gold: 'drop-shadow-[0_0_20px_rgba(245,158,11,0.9)]',
    emerald: 'drop-shadow-[0_0_15px_rgba(16,185,129,0.8)]',
    blue: 'drop-shadow-[0_0_15px_rgba(59,130,246,0.8)]',
    fire: 'drop-shadow-[0_0_20px_rgba(239,68,68,0.9)]',
  };

  const auraEffect = auraGlowMap[config.auraColor] || 'drop-shadow-[0_0_12px_rgba(6,182,212,0.6)]';

  return (
    <div className={`relative flex items-center justify-center transition-all duration-300 ${sizeClasses} ${className}`}>
      <svg
        viewBox="0 0 200 200"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className={`w-full h-full filter ${auraEffect} ${isTalking ? 'animate-bounce-short' : ''}`}
      >
        {/* Aura Outer Ring */}
        <circle
          cx="100"
          cy="100"
          r="88"
          stroke={bodyColor}
          strokeWidth="2"
          strokeDasharray="6 6"
          className="opacity-40 animate-spin-slow"
        />

        {/* Head Hat / Accessory */}
        {config.headItem === 'antenna' && (
          <g>
            <line x1="100" y1="45" x2="100" y2="25" stroke="#38bdf8" strokeWidth="4" strokeLinecap="round" />
            <circle cx="100" cy="20" r="7" fill="#38bdf8" className="animate-pulse" />
          </g>
        )}

        {config.headItem === 'grad_cap' && (
          <g>
            <path d="M60 40 L100 22 L140 40 L100 55 Z" fill="#1e293b" stroke="#f59e0b" strokeWidth="2" />
            <rect x="95" y="40" width="10" height="8" fill="#1e293b" />
            <path d="M130 40 L135 60" stroke="#f59e0b" strokeWidth="2" />
            <circle cx="135" cy="62" r="3" fill="#f59e0b" />
          </g>
        )}

        {config.headItem === 'headphones' && (
          <g>
            <path d="M55 75 C 55 35, 145 35, 145 75" stroke="#ef4444" strokeWidth="7" fill="none" strokeLinecap="round" />
            <rect x="42" y="65" width="16" height="30" rx="6" fill="#1e293b" stroke="#ef4444" strokeWidth="2" />
            <rect x="142" y="65" width="16" height="30" rx="6" fill="#1e293b" stroke="#ef4444" strokeWidth="2" />
          </g>
        )}

        {config.headItem === 'crown' && (
          <g>
            <path d="M70 45 L82 25 L100 38 L118 25 L130 45 Z" fill="#fbbf24" stroke="#d97706" strokeWidth="2" />
            <circle cx="82" cy="25" r="3" fill="#ef4444" />
            <circle cx="100" cy="25" r="3" fill="#3b82f6" />
            <circle cx="118" cy="25" r="3" fill="#ef4444" />
          </g>
        )}

        {config.headItem === 'wizard_hat' && (
          <g>
            <path d="M60 48 L100 10 L140 48 Z" fill="#6366f1" stroke="#a855f7" strokeWidth="2" />
            <ellipse cx="100" cy="48" rx="45" ry="8" fill="#4f46e5" />
            <path d="M92 30 L98 25 L104 30 L98 35 Z" fill="#fbbf24" />
          </g>
        )}

        {/* Robot Head Body */}
        <rect x="52" y="48" width="96" height="80" rx="20" fill="#1e293b" stroke={bodyColor} strokeWidth="4" />

        {/* Robot Ears */}
        <rect x="38" y="75" width="14" height="26" rx="4" fill={bodyColor} />
        <rect x="148" y="75" width="14" height="26" rx="4" fill={bodyColor} />

        {/* Face Screen Frame */}
        <rect x="62" y="60" width="76" height="52" rx="12" fill="#0f172a" stroke="#334155" strokeWidth="2" />

        {/* Robot Eyes */}
        {config.eyeType === 'cute' && (
          <g>
            <circle cx="82" cy="82" r="9" fill="#38bdf8" />
            <circle cx="118" cy="82" r="9" fill="#38bdf8" />
            <circle cx="85" cy="79" r="3" fill="#ffffff" />
            <circle cx="121" cy="79" r="3" fill="#ffffff" />
          </g>
        )}

        {config.eyeType === 'stars' && (
          <g fill="#fbbf24">
            <path d="M82 72 L85 80 L93 82 L85 84 L82 92 L79 84 L71 82 L79 80 Z" />
            <path d="M118 72 L121 80 L129 82 L121 84 L118 92 L115 84 L107 82 L115 80 Z" />
          </g>
        )}

        {config.eyeType === 'cyber' && (
          <g>
            <rect x="74" y="76" width="16" height="12" rx="3" fill="#00ffcc" />
            <rect x="110" y="76" width="16" height="12" rx="3" fill="#00ffcc" />
            <line x1="72" y1="82" x2="128" y2="82" stroke="#00ffcc" strokeWidth="1" strokeDasharray="2 2" />
          </g>
        )}

        {config.eyeType === 'visor' && (
          <g>
            <rect x="70" y="74" width="60" height="16" rx="8" fill="#ec4899" />
            <rect x="74" y="78" width="52" height="4" rx="2" fill="#fbcfe8" className="animate-pulse" />
          </g>
        )}

        {/* Mouth / Speaker */}
        {isTalking ? (
          <ellipse cx="100" cy="101" rx="10" ry="5" fill="#38bdf8" className="animate-ping" />
        ) : (
          <path d="M88 101 Q100 108 112 101" stroke="#94a3b8" strokeWidth="3" strokeLinecap="round" fill="none" />
        )}

        {/* Robot Neck & Chest */}
        <rect x="88" y="128" width="24" height="14" fill="#334155" />
        <path d="M60 142 L140 142 L150 185 L50 185 Z" fill="#1e293b" stroke={bodyColor} strokeWidth="3" />

        {/* Body Decals */}
        {config.bodyDecal === 'heart' && (
          <path d="M100 168 C100 168 88 158 88 152 C88 148 92 145 96 148 L100 152 L104 148 C108 145 112 148 112 152 C112 158 100 168 100 168 Z" fill="#ef4444" />
        )}

        {config.bodyDecal === 'lightning' && (
          <path d="M102 146 L92 160 L100 160 L96 172 L108 156 L100 156 Z" fill="#f59e0b" />
        )}

        {config.bodyDecal === 'atom' && (
          <g stroke="#38bdf8" strokeWidth="2" fill="none">
            <ellipse cx="100" cy="158" rx="12" ry="4" />
            <ellipse cx="100" cy="158" rx="12" ry="4" transform="rotate(60 100 158)" />
            <ellipse cx="100" cy="158" rx="12" ry="4" transform="rotate(120 100 158)" />
            <circle cx="100" cy="158" r="3" fill="#38bdf8" />
          </g>
        )}

        {config.bodyDecal === 'code' && (
          <text x="100" y="163" textAnchor="middle" fill="#10b981" fontSize="14" fontWeight="bold" fontFamily="monospace">
            &lt;/&gt;
          </text>
        )}

        {config.bodyDecal === 'star' && (
          <polygon points="100,148 103,155 110,155 105,160 107,167 100,162 93,167 95,160 90,155 97,155" fill="#f59e0b" />
        )}
      </svg>
    </div>
  );
};
