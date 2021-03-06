;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*              MODIFICA��ES PARA USO COM 12F675                   *
;*                FEITAS PELO PROF. MARDSON                        *
;*                    FEVEREIRO DE 2016                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*             ATIVIDADE_3 - PROJETO COM INFRAVERMELHO                           *
;*               SUANNY FABYNE DA SILVA VIEIRA                          *
;*         DESENVOLVIDO PELA MOSAICO ENGENHARIA E CONSULTORIA      *
;*   VERS�O: 1.0                           DATA: 17/06/03          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;* ESSE PROJETO RECEBE UM SINAL ATRAV�S DE UM CONTROLE E DECODIFICA*
;*-----------------------------------------------------------------*
;*		     MODELO PARA O PIC 12F675                      *
;*                                                                 *
;*                                                                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ARQUIVOS DE DEFINI��ES                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#INCLUDE <p12f675.inc>	;ARQUIVO PADR�O MICROCHIP PARA 12F675

	__CONFIG _BODEN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _MCLRE_OFF & _INTRC_OSC_NOCLKOUT
;foi necessario mudar o MCLRE para OFF '_MCLRE_OFF' para utilizar o GP3 como entrada
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    PAGINA��O DE MEM�RIA                         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;DEFINI��O DE COMANDOS DE USU�RIO PARA ALTERA��O DA P�GINA DE MEM�RIA
#DEFINE	BANK0	BCF STATUS,RP0	;SETA BANK 0 DE MEM�RIA
#DEFINE	BANK1	BSF STATUS,RP0	;SETA BANK 1 DE MAM�RIA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         VARI�VEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DOS NOMES E ENDERE�OS DE TODAS AS VARI�VEIS UTILIZADAS 
; PELO SISTEMA

	CBLOCK	0x20	;ENDERE�O INICIAL DA MEM�RIA DE
					;USU�RIO
		W_TEMP		;REGISTRADORES TEMPOR�RIOS PARA USO
		STATUS_TEMP	;JUNTO �S INTERRUP��ES
		AUXILIAR ;AUXILIAR QUE RECEBE OS BITS QUE O SINAL REPRESENTA
		CONT ;CONTADOR PARA FAZER A REPETI��O 7X A FIM DE DECODIFICAR O SINAL CORRETAMENTE
		CONTDELAY ;CONTADOR QUE AUXILIA NO DELAY
		;NOVAS VARI�VEIS

	ENDC			;FIM DO BLOCO DE MEM�RIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;A ENTRADA � POSTA NO GP3, SE 1 O SINAL DE ENTRADA EST� EM LOW, SE 0
;EST� EM REPOUSO

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SA�DAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;GP0, GP1, GP2 E GP4 � UTILIZADO PARA O DISPLAY. GP0 � O BIT MENOS 
;SIGNIFICATIVO E GP4 � O MAIS SIGNIFICATIVO, NESSA ORDEM: GP4,GP2,GP1 E GP0
;GP5 � UTILIZADO PARA O LED. 1 LIGA O LED, 0 DESLIGA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       VETOR DE RESET                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x00			;ENDERE�O INICIAL DE PROCESSAMENTO
	GOTO	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    IN�CIO DA INTERRUP��O                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDERE�O DE DESVIO DAS INTERRUP��ES. A PRIMEIRA TAREFA � SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERA��O FUTURA

	ORG	0x04			;ENDERE�O INICIAL DA INTERRUP��O
	MOVWF	W_TEMP		;COPIA W PARA W_TEMP
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    ROTINA DE INTERRUP��O                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AQUI SER� ESCRITA AS ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS
; INTERRUP��ES

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                 ROTINA DE SA�DA DA INTERRUP��O                  *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUP��O

SAI_INT
	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS		;MOVE STATUS_TEMP PARA STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W	;MOVE W_TEMP PARA W
	RETFIE

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 ROTINAS E SUBROTINAS                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRI��O DE FUNCIONAMENTO
; E UM NOME COERENTE �S SUAS FUN��ES.

SUBROTINA1

	;CORPO DA ROTINA

	RETURN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1				;ALTERA PARA O BANCO 1
	MOVLW	B'00000000' ;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)
	MOVWF	TRISIO		;COMO SA�DAS
	CLRF	ANSEL 		;DEFINE PORTAS COMO Digital I/O
	MOVLW	B'00000100' ;configurado na escala de 1:32, por motivos de facilitamento de contas
	MOVWF	OPTION_REG	;DEFINE OP��ES DE OPERA��O
	MOVLW	B'00000000'
	MOVWF	INTCON		;DEFINE OP��ES DE INTERRUP��ES
	CALL 0X3FF ;para configurar calibra��o
	MOVWF OSCCAL 
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERA��O DO COMPARADOR ANAL�GICO

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZA��O DAS VARI�VEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN
	MOVLW B'00000000'
	MOVWF AUXILIAR ;var auxiliar que receber� os bits do sinal
	MOVLW .7
	MOVWF CONT ;var que far� o loop a fim de ler o sinal corretamente
CHECK1  ;para checar o start bit
	BCF INTCON, T0IF ;zera o t0if, para n�o prejudicar a contagem do timer
	BTFSC GPIO, GP3 ;checa se o sinal de entrada que est� em high, mudou para low
	GOTO CHECK1 ;se nao mudou, volta para o check1 a fim de checar novamente
	MOVLW .190 ;se mudou de HIGH para low, come�ou um possivel start bit ;iniciamos o timer, para ver se pode ser um start bit atraves do tempo em low;
	MOVWF TMR0 ;usa-se o timer na escala 1:32, pois queremos checar o valor de 2400us. o valor calculado foi (256-181)=75, 75x32=181, mas nos testes com o monitor nao deu certo, pois havia algum delay que impossitava isso. Quando mudei para 190, aleatoriamente, funcionou
AINDANSUBIU
	BTFSC GPIO, GP3 ;checa se houve mudan�a de estado na entrada
	GOTO CHECK1 ;se mudou pra HIGH em menos de 2400us, entao nao � o start bit
	BTFSS INTCON, T0IF ;se continuou em LOW, a gente checa o T0IF para conferir se o timer j� estourou (passou de 255)
	GOTO AINDANSUBIU ;se veio pra c�, � porque o timer ainda nao acabou
CHECK2 ;o timer acabando e nao mudando de estado nesse tempo, entao � o start bit
	BTFSS GPIO, GP3 ;aqui, esperamos o start bit mudar de estado, no caso, ir pra HIGH
	GOTO CHECK2 ;se ainda nao foi pra HIGH, repete o processo e volta pra label CHECK2
CHECK3 ;nessa label, a gente espera o sinal que est� em HIGH, ir pra LOW, para iniciar a contagem do timer
	BTFSC GPIO, GP3 ;confere se foi pra LOW
	GOTO CHECK3 ;se n, volta
	BCF INTCON, T0IF ;se foi pra low, limpa o T0IF que foi setado anteriormente e inicia o contador
	MOVLW .237 ;iniciamos um contador de 600us, para chegar se � 0 ou 1 o bit a ser decodificado
	MOVWF TMR0 ;calculo (256-237)=19. 19x32=608us
CHECK4 ;aqui, checamos se o timer j� acabou sua contagem de 600us
	BTFSS INTCON, T0IF 
	GOTO CHECK4 ;se nao acabou, volta pra check4
	BTFSS GPIO, GP3 ;agora, vemos o estado do sinal, se depois de 600us ele subiu, entao foi um bit 0, se n�o subiu, foi um bit 1
	GOTO SALVA1 ;ou salva o bit 1, se ficar em LOW depois do timer de 600us
	GOTO SALVA0 ;ou salva o bit 0, se for pra HIGH
SALVA0 ;salva o bit 0
	BCF AUXILIAR, 7 ;colocamos o bit 0 no bit 7 de uma variavel auxiliar
	RRF AUXILIAR ;damos um shift para a direita, afim de guardar essa informa��o (bit 0) na variavel a cada leitura de bit
	DECFSZ CONT ;decrementa o contador que foi inicialmente definido como 7, pois o interesse � ler os 7 primeiros bits do sinal e guard�-los
	GOTO CHECK3 ;se o contador n acabou, como � 0 e sobe depois de 600us, volta para a label que quando est� em HIGH, checa se vai pra LOW
	GOTO DONESIGNAL ;se o contador acabou e j� foram feitas 7 intera��es, toda a informa��o j� est� guardada e vai para a label onde ser� tratada a variavel auxiliar
	
SALVA1
	BSF AUXILIAR, 7 ;colocamos o bit 0 no bit 7 de uma variavel auxiliar
	RRF AUXILIAR ;damos um shift para a direita, afim de guardar essa informa��o (bit 0) na variavel a cada leitura de bit
	DECFSZ CONT ;decrementa o contador que foi inicialmente definido como 7, pois o interesse � ler os 7 primeiros bits do sinal e guard�-los
	GOTO CHECK2 ;se o contador n acabou, como � 1 e sobe depois de apenas depois de 1200us, ele ainda est� em LOW, ent�o volta para a label que quando est� em LOW, espera ir pra HIGH, e ap�s isso, vai para HIGH e espera mudar de estado
	GOTO DONESIGNAL ;se o contador acabou e j� foram feitas 7 intera��es, toda a informa��o j� est� guardada e vai para a label onde ser� tratada a variavel auxiliar

DONESIGNAL 
	MOVLW .20
	MOVWF CONTDELAY ;iniciamos uma variavel auxiliar para auxiliar na contagem do timer
	MOVLW .10 
	SUBWF AUXILIAR, W ;AUXILIAR - 9. Fazemos uma compara��o de, se a auxiliar que guarda a informa��o do sinal, � maior que 9, ent�o ela n representa um d�gito a ser mostrado no display 
	BTFSS STATUS, C ;checa o carry, pra ver se a compara��o de auxiliar > 9 deu positiva ou negativa
	GOTO DISPLAY ; se auxiliar <= 9 exibimos num display a informa��o,
	GOTO LED ; se deu positiva, ou seja, auxiliar > 9, entao vamos para a label do led
LED ;label que pisca o led durante 100us
	BSF GPIO,GP0 ;seta os pinos do display para deixa-lo desligado antes de ligar o led 
	BSF GPIO,GP1
	BSF GPIO,GP2
	BSF GPIO,GP4
	BSF GPIO, GP5 ;liga o led
	GOTO DELAY ;inicia o delay
LEDOFF
	BCF GPIO, GP5
	GOTO MAIN
DELAY
	MOVLW .100 ;iniciamos o timer com 100, pois (256-100)=156, usando a escala, temos 156x32 ~= 5000us. Agora, faremos essa timer se repetir 20x, a fim de chegar a 100ms
	MOVWF TMR0
	BCF INTCON, T0IF ;limpa o t0if
	GOTO TIMER ;vai para a label que trata o delay
CABOUTIMER ;nessa label, decrementamos a variavel contdelay que foi iniciada com 20, para repetir essa contagem de 5000us do timer 20x, e chegar em 100ms
	DECFSZ CONTDELAY
	GOTO DELAY ;se o contdelay ainda nao contou 20x, entao volta para a label delay, iniciando o contador novamente
	GOTO LEDOFF ;se sim, entao deu o delay de 100ms e podendo desligar o led
	
TIMER ;espera contar 5000us
	BTFSS INTCON, T0IF 
	GOTO TIMER ;se n terminou, volta para o timer
	GOTO CABOUTIMER ;se terminou, vai para a label acaboutimer
DISPLAY	;nessa label, tratamos a exibi��o no display
	MOVLW .9
	SUBWF AUXILIAR, W ;AUXILIAR - 9 (fazemos essa compara��o pra facilitar o processo de exibi��o). Se a auxiliar for 9, no display ser� exibido 0, entao setamos diretamente. Se n�o, tratamos a informa��o em outra label
	BTFSS STATUS, Z 
	GOTO DISPLAY2 ; se auxiliar nao < 9, ir� para o tratamento do display
	GOTO DISPLAY9 ;se auxiliar = 9, ent�o ir� para a label que modificar� os pinos a fim de exibir 0
DISPLAY9 ;exibimos o valor 0 no display
	BCF GPIO, GP0
	BCF GPIO, GP1
	BCF GPIO, GP2
	BCF GPIO, GP4
	GOTO MAIN
DISPLAY2 ;exibimos o de 1 a 0 no display
	MOVLW .1
	ADDWF AUXILIAR ;como, de 1 � 9, sempre exibir� auxiliar+1 no display, ent�o adicionamos o valor 1 a nossa variavel 
	BTFSS AUXILIAR, 0 ;� CHECADO O BIT MENOS SIGNIFICATIVO DA VARIAVEL AUXilIAR, QUE CONTEM O VALOR DO SINAl
	GOTO ZERA1 ;SE O BIT MENOS SIGNIFICATIVO FOR 0, DESVIA
	BSF GPIO, GP0 ;SE FOR 1, � SETADA A PORTA 1
VOLTA1
	RRF AUXILIAR ;AGORA, FAZEMOS UM SHIFT PARA DIREITA, AFIM DE OBTER O PROXIMO BIT MENOS SIGNICATIVO, E CHECA-LO
	BTFSS AUXILIAR, 0 ;CHECAMOS O PROXIMO BIT, DEPOIS DE FAZER O DESLOCAMENTO
	GOTO ZERA2
	BSF GPIO, GP1 ;SE 1, SETA
VOLTA2	
	RRF AUXILIAR ;REPETE O MESMO PROCESSO DE DESLOCAMENTO E CHECA O BIT
	BTFSS AUXILIAR, 0
	GOTO ZERA4
	BSF GPIO, GP2
VOLTA4	
	RRF AUXILIAR ;REPETE O MESMO PROCESSO DE DESLOCAMENTO E CHECA O BIT
	BTFSS AUXILIAR, 0
	GOTO ZERA5
	BSF GPIO, GP4 ;SETA A ULTIMA PORTA
VOLTA5
	GOTO MAIN
	
ZERA1
	BCF GPIO, GP0 ;MUDA O VALOR DA PORTA PARA 0
	GOTO VOLTA1 ;VOLTA PARA A LABEL DISPLAY, PARA VOLTAR AO FLUXO NORMAL
ZERA2 
	BCF GPIO, GP1 ;MUDA O VALOR DA PORTA PARA 0
	GOTO VOLTA2 ;VOLTA PARA A LABEL DISPLAY, PARA VOLTAR AO FLUXO NORMAL
ZERA4 
	BCF GPIO, GP2 ;MUDA O VALOR DA PORTA PARA 0
	GOTO VOLTA4 ;VOLTA PARA A LABEL DISPLAY, PARA VOLTAR AO FLUXO NORMAL
ZERA5 
	BCF GPIO, GP4 ;MUDA O VALOR DA PORTA PARA 0
	GOTO VOLTA5 ;VOLTA PARA A LABEL DISPLAY, PARA VOLTAR AO FLUXO NORMAL
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END

