#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform vec3 daytime;
uniform sampler2D backbuffer;
uniform int frame;
vec3 skyColor = vec3(0.0);
const float pi = 3.141596;
const float e= 2.7182818284;
float shipShift;

float getCos(float phi, float r){
 float fCos = r*cos(phi);
  return fCos;
}

float getSin(float phi, float r){
 float fSin = r*sin(2.*phi);
  return fSin;
}

vec3 getGridColor()
{
 vec2 uv = abs(gl_FragCoord.xy-resolution.xy/2.)/resolution.xx;
 float accent = sqrt(uv.x* uv.x + uv.y* uv.y);
 return vec3(sqrt(sin(accent - time)), sqrt(sin(accent - time + 6.28/3.)),sqrt(sin(accent - time +12.56/3.)));
}

vec3 getColorizedGrid(vec4 inCol){
 float ftime = time/10.;
 float phi = 6.28*(ftime - floor(ftime));
 float r = 2.;
 float fCos = getCos(phi, r);
 float fSin = getSin(phi, r);
 vec2 shift = vec2(fCos, fSin);
 float alligmentRoot = min(resolution.x, resolution.y);
 float gridWidth = alligmentRoot/100.;
 float gridPixelSize = gridWidth*10.;
 if(floor (mod(shift.y * alligmentRoot/5. + gl_FragCoord.y, gridPixelSize)) < gridWidth || floor(mod(shift.x * alligmentRoot/2. + gl_FragCoord.x, gridPixelSize)) < gridWidth) return getGridColor();
 return vec3(0.);
}

float getGraphHeight(){
 return resolution.y/7. + resolution.y/20. * sin(time + gl_FragCoord.x/200.);
}

float getGraphHeight(float x){
 return resolution.y/7. + resolution.y/20. * sin(time + x/200.);
}

vec4 getPulseColor(float relDist, float surgeWidth, float phase){
 float dist=relDist/surgeWidth;
 float col=1.-pow(dist,1.2);
 return vec4(1.1*(1.-phase)*col);
}

vec4 renderMoonPulse(vec4 inCol, float moonDist, float moonRadius){
 float clearSurgePhase = 0.;
 if(mod(time, 3.)>=2.) clearSurgePhase = time - floor(time);
 float surgePhase=pow(clearSurgePhase, 0.3);
 float maxSurgeDistance = 0.8*min(resolution.x, resolution.y);
 float surgeWidth = 0.05 * min(resolution.x, resolution.y)*(1.-4.*pow(clearSurgePhase-0.5,2.))*2.;
 float surgeDistance = maxSurgeDistance*surgePhase;
 float relDist = abs(moonDist-surgeDistance);
 if(relDist<=surgeWidth) return getPulseColor(relDist, surgeWidth, surgePhase);
 return inCol;
}

vec4 renderNight(vec4 inCol){
 float hours = daytime.x <12.? daytime.x+18.:daytime.x-6.;
 float moonAngle = pi - (pi/4. + 1.23 * ((hours -12.)*3600. + daytime.y * 60. + daytime.z)/43200.);
 float orbitRadius = resolution.y /1.5;
 vec2 moonPos = vec2( cos(moonAngle) * orbitRadius +resolution.x/2., sin(moonAngle) * orbitRadius);
 float moonRadius = resolution.x/8.;
 float shadeRadius = resolution.x/6.;
 vec2 normalizedCoord = gl_FragCoord.xy - moonPos.xy;
 vec2 normalizedShade = gl_FragCoord.xy - moonPos.xy + vec2(55.,-55.);
 float moonDistance = sqrt(normalizedCoord.x * normalizedCoord.x + normalizedCoord.y*normalizedCoord.y);
 float shadeDistance = sqrt(normalizedShade.x * normalizedShade.x + normalizedShade.y*normalizedShade.y);
 vec4 outCol = inCol;
 if(moonDistance<=moonRadius) {
  float channelColor = 1.-pow(moonDistance/moonRadius,20.);
  outCol = vec4(channelColor, channelColor, channelColor,1.);
  }
 if(shadeDistance<=shadeRadius && moonDistance<=moonRadius) {
  float shadeCol = pow(shadeDistance/shadeRadius - moonDistance/moonRadius,5.);
  return mix(outCol, vec4(shadeCol,shadeCol,shadeCol,1.), 1.);
  }
 return renderMoonPulse(outCol, moonDistance, moonRadius);
}

vec4 getCrownColor(float dist, float range){
 return (1. -dist/range)*vec4(1.0, 1.0, 0.5, 1.);
}

vec4 mixc(vec4 fi, vec4 sd, float c){
 return vec4(mix(fi.x, sd.x, c), mix(fi.y, sd.y, c), mix(fi.z, sd.z, c), mix(fi.t, sd.t, c));
}

vec4 renderCrown(vec2 coord, float dist, vec4 inCol, float sunRadius){
 vec2 relativeCoord = gl_FragCoord.xy - coord.xy;
 float pixelAngle = atan(relativeCoord.y/relativeCoord.x);
if(relativeCoord.x < 0.) pixelAngle = pixelAngle + pi;
 float root = min(resolution.x, resolution.y);
 float firstAngle = pixelAngle + time/40.;
 float mx = 0.4*root + 0.005* root * sin(24.*pixelAngle + time);
 vec4 col = inCol;
 if(dist<mx) col = 0.5*getCrownColor(dist-sunRadius, mx-sunRadius);
 if(mod(firstAngle, pi/4.) < pi/14. && (dist < mx)) col = mixc(col, getCrownColor(dist-sunRadius, mx-sunRadius), 0.5);
 if(mod(pixelAngle - time/23., pi/9.) < pi/12. && (dist < mx)) col = mixc(col, getCrownColor(dist-sunRadius, mx-sunRadius), 0.5);
 if(mod(firstAngle + time/25., pi/4.5) < pi/14. && (dist < mx)) col = mixc(col, getCrownColor(dist-sunRadius, mx-sunRadius), 0.5);
 if(mod(firstAngle - time/32., pi/6.1) < pi/10. && (dist < mx)) col = mixc(col, getCrownColor(dist-sunRadius, mx-sunRadius), 0.5);
 return col;
}



vec4 renderDay(vec4 inCol){
 float hours = daytime.x - 6.;
 float sunAngle = pi - (pi/4. + 1.3*(hours* 3600. + daytime.y*60. + daytime.z)/57600.);
 float orbitRadius = resolution.y /1.5;
  float sunRadius = resolution.x/7.;
  vec2 sunPos = vec2( cos(sunAngle) * orbitRadius +resolution.x/2., sin(sunAngle) * orbitRadius);
  vec2 normalizedCoord = gl_FragCoord.xy - sunPos.xy;
  float sunDistance = sqrt(normalizedCoord.x * normalizedCoord.x + normalizedCoord.y*normalizedCoord.y);
  if(sunDistance<=sunRadius){
   return vec4(1.0,1.0,1.- sunDistance/(2.*sunRadius),1.);
  }
  else return renderCrown(sunPos, sunDistance, inCol, sunRadius);
}

vec4 renderTime(vec4 inCol){
 if(daytime.x > 22. || daytime.x<6.) return renderNight(inCol);
 return renderDay(inCol);
}

vec4 visualizeSky(){
 return vec4(skyColor,1.);
}

vec4 renderShip(vec4 inCol){
 shipShift = resolution.x*0.4+resolution.x*0.2*sin(time/10.);
 float graphHeight = getGraphHeight(shipShift);
 float graphTan = 0.6*cos(shipShift/200.+time);
 float angle = atan(graphTan);
 vec2 pos = vec2(shipShift-gl_FragCoord.x, gl_FragCoord.y-graphHeight);
 mat2 rotationMatrix;
 rotationMatrix[0] = vec2(cos(angle), sin(angle));
 rotationMatrix[1] = vec2(-sin(angle), cos(angle));
 pos = rotationMatrix*pos.xy;
 pos.xy = pos.xy;
 if((abs(pos.x)<resolution.x/18. && pos.y>=0. && pos.y<resolution.y/40. )
  || (abs(pos.x)>resolution.x/18. && abs(pos.x)<resolution.x/10. && pos.y>abs(pos.x)-resolution.y/40. && pos.y<resolution.y/40.)
  || (2.*-abs(pos.x)+resolution.y/22. >= pos.y)) return vec4(1.);
 return inCol;
}

vec4 renderBackwaves(vec4 inCol){
 if(inCol.xyz != vec3(skyColor)) {

 }
 return inCol;
}

void main() {
 shipShift = 0.6*resolution.x;
 vec4 gridCol = visualizeSky();
 gridCol = renderShip(gridCol);
 float height = getGraphHeight();
 if(gl_FragCoord.y < height) gridCol = vec4(getColorizedGrid(gridCol), 1.);
 else if(gl_FragCoord.y < resolution.y/150.+height) gridCol = vec4(getGridColor(), 1.0);
  else gridCol = renderTime(gridCol);
 gl_FragColor = gridCol;
}
