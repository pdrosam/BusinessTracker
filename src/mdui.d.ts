declare module 'preact' {
  namespace JSX {
    interface IntrinsicElements {
      [tag: `mdui-${string}`]: Record<string, unknown>;
    }
  }
}

export {};