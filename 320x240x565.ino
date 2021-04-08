// refer from https://gist.github.com/muhammadyaseen/75490348a4644dcbc70f
// Author: muhammadyaseen
// Apply it on RedBear 
// Add the configuration for ov7670 by Beitong Tian
#define SIO_C A5
#define SIO_D A4
#define SIO_CLOCK_DELAY 100



void setup()
{
  //pinMode(D8,OUTPUT);
  
//  while(1)
//  {
//    digitalWrite(8,HIGH);
//    delayMicroseconds(SIO_CLOCK_DELAY);    
//    digitalWrite(8,LOW);
//    delayMicroseconds(SIO_CLOCK_DELAY);    
//  }
    
  Serial.begin(9600);
  Serial.println("Start InitOV7670 test program");
  //digitalWrite(D8,HIGH);delayMicroseconds(SIO_CLOCK_DELAY);   
  //digitalWrite(D8,LOW);delayMicroseconds(SIO_CLOCK_DELAY);   
  //digitalWrite(D8,HIGH);delayMicroseconds(SIO_CLOCK_DELAY);   
 
  if(InitOV7670())    
    Serial.println("InitOV7670 OK");
  else
    Serial.println("InitOV7670 NG");
  
  
}
 
void loop()
{
}
 
 
void InitSCCB(void) //SCCB Initialization
{
  pinMode(SIO_C,OUTPUT);
  pinMode(SIO_D,OUTPUT);
  
  digitalWrite(SIO_C,HIGH);
  digitalWrite(SIO_D,HIGH);
  
  Serial.println("InitSCCB - Port Direction Set & Set High OK");
}
 
void StartSCCB(void) //SCCB Start
{
  Serial.println("StartSCCB");
 
  digitalWrite(SIO_D,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_C,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_D,LOW);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_C,LOW);
  delayMicroseconds(SIO_CLOCK_DELAY);
}
 
void StopSCCB(void) //SCCB Stop
{
  //Serial.println("StopSCCB");
 
  digitalWrite(SIO_D,LOW);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_C,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
  
  digitalWrite(SIO_D,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
}
 
bool SCCBWrite(byte m_data)
{
  unsigned char j;
  bool success;

  for ( j = 0; j < 8; j++ ) //Loop transmit data 8 times
  {
    if( (m_data<<j) & 0x80 )
      digitalWrite(SIO_D,HIGH);
    else
      digitalWrite(SIO_D,LOW);
  
    delayMicroseconds(SIO_CLOCK_DELAY);
    
  
  digitalWrite(SIO_C,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
    
  digitalWrite(SIO_C,LOW);
    delayMicroseconds(SIO_CLOCK_DELAY);
  }
 

  digitalWrite(8,LOW); //debug
  
  pinMode(SIO_D,INPUT); // I pass a bus of SIO_D to slave (OV7670)
  digitalWrite(SIO_D,LOW); // Pull-up prevention  --this line is not present in embedded programmer lib
  delayMicroseconds(SIO_CLOCK_DELAY);
 
  digitalWrite(8,HIGH); //debug
  
  digitalWrite(SIO_C,HIGH);
  delayMicroseconds(SIO_CLOCK_DELAY);
 
  digitalWrite(8,LOW); //debug
  
  if(digitalRead(SIO_D)==HIGH)
    success= false;
  else
    success= true; 

  digitalWrite(SIO_C,LOW);
  delayMicroseconds(SIO_CLOCK_DELAY); 
  
  pinMode(SIO_D,OUTPUT); //Return the bus of SIO_D to master (Arduino)
  
  //delayMicroseconds(SIO_CLOCK_DELAY); 
  //digitalWrite(SIO_D,LOW);
  //delayMicroseconds(SIO_CLOCK_DELAY); 
 
  //pinMode(SIO_C,OUTPUT); //Return the bus of SIO_C to master (Arduino)
 
  return success;  
}
 
bool InitOV7670(void)
{


  InitSCCB();
  //scale and color 
  WriteOV7670(0x12, 0x80);
  WriteOV7670(0x0C, 0x00);
  WriteOV7670(0x12, 0x04);
  WriteOV7670(0x40, 0xC0 + 0x10);

  //color saturation
  WriteOV7670(0xc9, 0x00); //default c0

  //enable AWB
  WriteOV7670(0x13, 0x8f);
  


  //color matrix
    WriteOV7670(0x4f, 0x80); //red in red channel
    WriteOV7670(0x50, 0x80); //green in red channel
    WriteOV7670(0x51, 0x00); //blue in red channel
    WriteOV7670(0x52, 0x22); //red in blue channel
    WriteOV7670(0x53, 0x5e); //green in blue channel
    WriteOV7670(0x54, 0x80); //blue in blue channel
    WriteOV7670(0x56, 0x40);
    WriteOV7670(0x58, 0x9e);
    WriteOV7670(0x59, 0x88);
    WriteOV7670(0x5a, 0x88);
    WriteOV7670(0x5b, 0x44);
    WriteOV7670(0x5c, 0x67);
    WriteOV7670(0x5d, 0x49);
    WriteOV7670(0x5e, 0x0e);
    WriteOV7670(0x69, 0x00);
    WriteOV7670(0x6a, 0x40);
    WriteOV7670(0x6b, 0x0a);
    WriteOV7670(0x6c, 0x0a);
    WriteOV7670(0x6d, 0x55);
    WriteOV7670(0x6e, 0x11);
    WriteOV7670(0x6f, 0x9f);
    WriteOV7670(0xb0, 0x84);

  //320x240
    WriteOV7670(0x0c, 0x04);
    WriteOV7670(0x3e, 0x19);
    WriteOV7670(0x73, 0x01);

  //enables AEC and AWB  
    WriteOV7670(0x13, 0x8f);
    
  

  


  return true; 
}  
 
////////////////////////////
//To write to the OV7670 register: 
// function Return value: Success = 1 failure = 0
bool WriteOV7670(char regID, char regDat)
{
  StartSCCB();
  if( ! SCCBWrite(0x42) )
  {
        Serial.println(" Write Error 0x42");
      StopSCCB();
    return false;
  }
  
  delayMicroseconds(SIO_CLOCK_DELAY);

    if( ! SCCBWrite(regID) )
  {
    StopSCCB();
    return false;
  }
  delayMicroseconds(SIO_CLOCK_DELAY);
    if( ! SCCBWrite(regDat) )
  {
    StopSCCB();
    return false;
  }
  
    StopSCCB();
  
    return true;
}
