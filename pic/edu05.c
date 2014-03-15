#include "edu05.h"
#include "p18f24j50.h"
#include "TimeDelay.h"


char PORTBModeState=1;
char PORTBImage=0x00;
char demo=0x00;

void inOutModePortB(int param){ //0->output 1->input
	if(param==0){
		TRISCbits.TRISC7=0;PORTCbits.RC7=0;
    	TRISCbits.TRISC6=0;PORTCbits.RC6=0;
		TRISB=0x00;		
	}else if(param==1){
		TRISB=0xFF;
		TRISCbits.TRISC7=0;PORTCbits.RC7=1;
    	TRISCbits.TRISC6=0;PORTCbits.RC6=1;
	}
}

char readPortB(void){inOutModePortB(1);return PORTB;}
void writePortB(char value){inOutModePortB(0);LATB=value;}	

void setPORTBImage(char value){PORTBImage=value;}
char getPORTBImage(void){return PORTBImage;}	
void applyPORTBImage(void){writePortB(PORTBImage);}
void setPORTBMode(char value){PORTBModeState=value;}
char getPORTBMode(void){return PORTBModeState;}

char reverseLSB(char value){
	char temp0=(value&0b00000001)<<3;
	char temp1=(value&0b00000010)<<1;
	char temp2=(value&0b00000100)>>1;
	char temp3=(value&0b00001000)>>3;
	char result=(value&0b11110000);
	result=result|temp0|temp1|temp2|temp3;
	return result;
}	

void lcdSendConfigByte(char value){	
	char LSB=value&0b00001111;
	TRISCbits.TRISC2=0;PORTCbits.RC2=0;		
	writePortB(reverseLSB(LSB));
	PORTCbits.RC2=1;Delay10us(250);
	PORTCbits.RC2=0;Delay10us(100);	
}	

void lcdSendByte(char value){
	char LSB=value&0b00001111;
	char MSB=((value&0b11110000)>>4)&0b00001111;
	LSB=LSB|0b10000000;MSB=MSB|0b10000000;
	TRISCbits.TRISC2=0;PORTCbits.RC2=0;	
	writePortB(reverseLSB(MSB));
	PORTCbits.RC2=1;Delay10us(75);
	PORTCbits.RC2=0;Delay10us(1);
	writePortB(reverseLSB(LSB));
	PORTCbits.RC2=1;Delay10us(75);
	PORTCbits.RC2=0;Delay10us(1);
}	

void lcdWriteString(char string[]){
	int i=0;
	while(string[i]!=0){
		lcdSendByte(string[i]);
		i++;
	}
}

void lcdInit(void){
	lcdSendConfigByte(0x00);
	lcdSendConfigByte(0x01);
	lcdSendConfigByte(0x00);
	lcdSendConfigByte(0x00);
	lcdSendConfigByte(0x01);

	lcdSendConfigByte(0x03);
	lcdSendConfigByte(0x03);
	lcdSendConfigByte(0x03);

	lcdSendConfigByte(0x02);

	lcdSendConfigByte(0x02);
	lcdSendConfigByte(0x08);

	lcdSendConfigByte(0x00);
	lcdSendConfigByte(0x0C);

	lcdSendConfigByte(0x00);
	lcdSendConfigByte(0x06);

	lcdSendConfigByte(0x00);
	lcdSendConfigByte(0x01);
}	

void setDemoParam(char value){demo=value;}
char getDemoParam(void){return demo;}

void getAnalogInput(char number, char * MSB, char * LSB){
	char tab[2];
	ADCON1=0b00000100;
	if(number==0){ADCON0=0b00000001;}//SENS AN0
	if(number==1){ADCON0=0b00000101;}//RV2 AN1
	if(number==2){ADCON0=0b00001001;}//RV1 AN2
	if(number==3){ADCON0=0b00001101;}//LDR AN3
	if(number==4){ADCON0=0b00010001;}//NTC AN4
	ADCON0bits.GO=1;
	while(ADCON0bits.GO==1);
	*MSB=0b00000011&(ADRESH>>6);
	*LSB=(0b11111100&(ADRESH<<2))|(0b00000011&(ADRESL>>6));
}	

void EDU05Init(void){
   	char i=0, j=1, counter=0;
	char myString1 []= " EDU05 firmware                           open sources"; 	
char myString2 []= " EDU05 firmwae                           open sources"; 	
 	TRISC=0b00111000;
	ANCON0=0b11110000;                  // Default all pins to digital
    ANCON1=0xFF;
	
	//lcd
	RPOR11=0b00001110;//14 RC0=PWM1
	T2CON=0x04;
	CCP1CON=0x0c;
	PR2=199;
	CCPR1L=((float)5/255)*199;
	
	//led		
	RPOR12=0b00010010;//18 RC1=PWM1			
	T2CON=0x04;
	CCP2CON=0x0c;
	PR2=199;
	CCPR2L=((float)255/255)*199;

	for(i=0;i<8;i++){
		writePortB(j);	
		j=j<<1;	
		Delay10us(10000);
	}

	//if(getDemoParam()==0x00){
		lcdInit();
		lcdWriteString(myString1);
	//}	

	j=128;
	for(i=0;i<8;i++){
		writePortB(j);	
		j=j>>1;
		Delay10us(10000);
	}

	writePortB(0x00);

	/*lcdSendConfigByte(0x00);
	lcdSendConfigByte(0x01); 

	for(counter=0;counter<60;counter++){
		lcdSendConfigByte(0x00);
		lcdSendConfigByte(0x01); 
		lcdSendByte(counter+48);
		Delay10us(100000);	
	}*/
	
}


