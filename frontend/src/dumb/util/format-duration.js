import {fmt} from 'human-duration';

export default function formatDuration(seconds) {
  return fmt(seconds * 1000).segments(2);
}
