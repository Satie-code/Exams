async function testAdmin() {
  try {
    const loginRes = await fetch('http://localhost:5000/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'admin@exams.local', password: 'Pass123!' })
    });
    
    const loginData = await loginRes.json();
    console.log('Login Response:', loginData);
    
    // Fallback to checking all properties
    const token = loginData.accessToken || loginData.access_token || loginData.token;
    console.log('Got token:', token);
    
    const dashRes = await fetch('http://localhost:5000/admin/dashboard', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    const dashData = await dashRes.json();
    console.log('DASHBOARD DATA:', JSON.stringify(dashData, null, 2));
  } catch (err) {
    console.error('ERROR:', err);
  }
}

testAdmin();
