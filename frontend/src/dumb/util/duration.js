import React from 'react';
import {fmt} from 'human-duration';

export default function Duration({val}) {
  return <span>{fmt(val * 1000).segments(2)}</span>;
}
