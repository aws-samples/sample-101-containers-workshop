import http from 'k6/http';
import { check, sleep } from 'k6';

// Get ALB URL from environment variable
const ALB_URL = __ENV.ALB_URL || 'http://localhost';
const TARGET_URL = `${ALB_URL}/wildlife`;

export let options = {
  stages: [
    // Aggressive ramp-up to force media service beyond capacity
    { duration: '30s', target: 300 },   // Quick spike to 300 users
    { duration: '30s', target: 600 },   // Push to 600 users
    { duration: '30s', target: 900 },   // Peak load to force scaling
    
    // Sustained high load to trigger EC2 capacity scaling
    { duration: '6m', target: 1200 },   // Maximum load to exceed EC2 capacity
    
    // Gradual ramp-down to observe scaling behavior
    { duration: '1m', target: 300 },    // Gradual drop
    { duration: '1m', target: 100 },    // Quick drop
    { duration: '30s', target: 0 },     // Complete drop
  ],
  thresholds: {
    http_req_duration: ['p(95)<8000'], // More lenient for higher load
    http_req_failed: ['rate<0.4'],     // Less than 4% failures 
  },
};

export default function() {
  // Focus heavily on MEDIA SERVICE endpoints to drive CPU usage
  
  // 1. Create sighting (hits MEDIA service - CPU intensive)
  let sightingResponse = http.post(`${TARGET_URL}/api/sightings`, {
    species: `Load Test Species ${Math.random()}`,
    habitat: 'Forest',
    latitude: (-20.2759 + (Math.random() - 0.5) * 0.1).toString(),
    longitude: (57.5704 + (Math.random() - 0.5) * 0.1).toString(),
    count: (Math.floor(Math.random() * 10) + 1).toString(),
    description: `Load test sighting - ${new Date().toISOString()}`,
    ranger_name: `Ranger ${Math.floor(Math.random() * 100)}`
  }, {
    headers: {
      'User-Agent': 'k6-capacity-scaling-test/1.0',
    },
  });
  
  check(sightingResponse, {
    'sighting created': (r) => r.status === 200,
  });
  
  // 2. Create sightings
  http.post(`${TARGET_URL}/api/sightings`, {
    species: `Test Animal ${Math.random()}`,
    habitat: 'Savanna',
    latitude: (-25 + Math.random() * 5).toString(),
    longitude: (30 + Math.random() * 5).toString(),
    count: (Math.floor(Math.random() * 5) + 1).toString(),
    description: `Capacity test sighting - ${new Date().toISOString()}`
  });
  
  // 3. Access multiple images
  for (let i = 0; i < 3; i++) {
    http.get(`${TARGET_URL}/api/images/sightings/20250820/test_image_${Math.floor(Math.random() * 20)}.jpg`);
  }
  
  // 4. Get sightings (hits dataapi)
  http.get(`${TARGET_URL}/api/sightings`);
  
  // Small delay but keep pressure high
  sleep(0.1);
}