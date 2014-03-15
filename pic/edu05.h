#ifndef EDU05_H
#define EDU05_H
	void EDU05Init(void);
	void setPORTBImage(char value);
	char getPORTBImage(void);
	void applyPORTBImage(void);
	void setPORTBMode(char value);
	char getPORTBMode(void);
	char readPortB(void);
	void writePortB(char value);
	char reverseLSB(char value);
	void lcdSendConfigByte(char value);
	void lcdSendByte(char value);
	void lcdWriteString(char string[]);
	void lcdInit(void);
	void inOutModePortB(int param);
	void setDemoParam(char value);
	char getDemoParam(void);
	void getAnalogInput(char number, char * MSB, char * LSB);
#endif