import http from 'k6/http';
import { check, sleep } from 'k6';

// Get ALB URL from environment variable
const ALB_URL = __ENV.ALB_URL || 'http://localhost';
const TARGET_URL = `${ALB_URL}/wildlife`;

export let options = {
  stages: [
    // Aggressive ramp-up to trigger scaling frontend service scaling
    { duration: '30s', target: 150 },   // Quick spike to 150 users
    { duration: '1m', target: 250 },    // Push to ensure CPU > 70%
    { duration: '2m', target: 300 },    // Peak load to trigger multiple scale-outs
    
    // Sustained high load to see scaling events
    { duration: '4m', target: 300 },    // Hold peak load
    
    // Quick ramp-down
    { duration: '1m', target: 100 },    // Quick drop
    { duration: '1m', target: 50 },     // Light load
    { duration: '30s', target: 0 },     // Complete drop
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'], // 95% of requests under 3s
    http_req_failed: ['rate<0.15'],    // Less than 15% failures 
  },
};

export default function() {
  // Multiple requests to increase CPU load per user
  let response1 = http.get(TARGET_URL, {
    headers: {
      'User-Agent': 'k6-capacity-scaling-test/1.0',
    },
  });
  
  // Check response
  check(response1, {
    'status is 200': (r) => r.status === 200,
    'response time < 5s': (r) => r.timings.duration < 5000,
  });
  
  // Add requests to stress frontend
  http.get(`${TARGET_URL}/api/animals`);
  http.get(`${TARGET_URL}/api/sightings`);
  
  // Small delay but keep pressure high
  sleep(0.3);
  
  // Additional request burst to stress CPU
  http.get(TARGET_URL);
}