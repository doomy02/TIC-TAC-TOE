.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "TIC-TAC-TOE",0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

con db 1
con1 db 1
matrix db 2,2,2,2,2,2,2,2,2
varx db 0
var0 db 0

button_x EQU 100
button_y EQU 50
button_size EQU 80

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text

make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
	
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
	
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
	
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
	
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
	
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

line_horizontal macro x, y, len, color
local bucla_line
	mov EAX, y
	mov EBX, area_width
	mul EBX
	add EAX, x
	shl EAX, 2 
	add EAX, area
	
	mov ECX, len
bucla_line:
	mov dword ptr[EAX], color
	add EAX, 4
	loop bucla_line
endm

line_vertical macro x, y, len, color
local bucla_line
	mov EAX, y
	mov EBX, area_width
	mul EBX
	add EAX, x
	shl EAX, 2 
	add EAX, area
	
	mov ECX, len
bucla_line:
	mov dword ptr[EAX], color
	add EAX, 4*area_width
	loop bucla_line
endm

line_diagonally_principal macro x, y, len, color
local bucla_line
	mov EAX, y
	mov EBX, area_width
	mul EBX
	add EAX, x
	shl EAX, 2 
	add EAX, area
	
	mov ECX, len
bucla_line:
	mov dword ptr[EAX], color
	add EAX, 4*(area_width+1)
	loop bucla_line
endm

line_diagonally_secundar macro x, y, len, color
local bucla_line
	mov EAX, y
	mov EBX, area_width
	mul EBX
	add EAX, x
	shl EAX, 2 
	add EAX, area
	
	mov ECX, len
bucla_line:
	mov dword ptr[EAX], color
	add EAX, 4*(area_width-1)
	loop bucla_line
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
patrat_1:
	mov EAX, [EBP+arg2]
	cmp EAX, button_x
	jl  button_fail
	cmp EAX, button_x + button_size
	jg patrat_2
	
	mov EAX, [EBP+arg3]
	cmp EAX, button_y
	jl button_fail
	cmp EAX, button_y + button_size
	jg patrat_4
	
	cmp con, 1
	je litera_p1x
	; cmp con, 1
	; jne cifra_p10

patrat_2:
	mov EAX, [EBP+arg2]
	cmp EAX, button_x + button_size
	jl  button_fail
	cmp EAX, button_x + 2*button_size
	jg patrat_3
	
	mov EAX, [EBP+arg3]
	cmp EAX, button_y
	jl button_fail
	cmp EAX, button_y + button_size
	jg patrat_5
	
	cmp con, 1
	je litera_p2x
	; cmp con, 1
	; jne cifra_p20

	
patrat_3:
	mov EAX, [EBP+arg2]
	cmp EAX, button_x + button_size
	jl  button_fail
	cmp EAX, button_x + 3*button_size
	jg button_fail
	
	mov EAX, [EBP+arg3]
	cmp EAX, button_y
	jl button_fail
	cmp EAX, button_y + button_size
	jg patrat_6
	
	cmp con, 1
	je litera_p3x
	; cmp con, 1
	; jne cifra_p30
	
patrat_4:
	mov EAX, [EBP+arg2]
	cmp EAX, button_x
	jl  button_fail
	cmp EAX, button_x + button_size
	jg patrat_5
	
	mov EAX, [EBP+arg3]
	cmp EAX, button_y + button_size
	jl button_fail
	cmp EAX, button_y + 2*button_size
	jg patrat_7
	
	cmp con, 1
	je litera_p4x
	; cmp con, 1
	; jne cifra_p40
	
patrat_5:
	mov EAX, [EBP+arg2]
	cmp EAX, button_x + button_size
	jl  button_fail
	cmp EAX, button_x + 2*button_size
	jg patrat_6
	
	mov EAX, [EBP+arg3]
	cmp EAX, button_y + button_size
	jl button_fail
	cmp EAX, button_y + 2*button_size
	jg patrat_8
	
	cmp con, 1
	je litera_p5x
	; cmp con, 1
	; jne cifra_p50
	
patrat_6:
	mov EAX, [EBP+arg2]
	cmp EAX, button_x + button_size
	jl  button_fail
	cmp EAX, button_x + 3*button_size
	jg patrat_7
	
	mov EAX, [EBP+arg3]
	cmp EAX, button_y + button_size
	jl button_fail
	cmp EAX, button_y + 2*button_size
	jg patrat_9
	
	cmp con, 1
	je litera_p6x
	; cmp con, 1
	; jne cifra_p60
	
patrat_7:
	mov EAX, [EBP+arg2]
	cmp EAX, button_x
	jl  button_fail
	cmp EAX, button_x + button_size
	jg patrat_8
	
	mov EAX, [EBP+arg3]
	cmp EAX, button_y + 2*button_size
	jl button_fail
	cmp EAX, button_y + 3*button_size
	jg button_fail
	
	cmp con, 1
	je litera_p7x
	; cmp con, 1
	; jne cifra_p70
	
patrat_8:
	mov EAX, [EBP+arg2]
	cmp EAX, button_x + button_size
	jl  button_fail
	cmp EAX, button_x + 2*button_size
	jg patrat_9
	
	mov EAX, [EBP+arg3]
	cmp EAX, button_y + 2*button_size
	jl button_fail
	cmp EAX, button_y + 3*button_size
	jg button_fail
	
	cmp con, 1
	je litera_p8x
	; cmp con, 1
	; jne cifra_p80
	
patrat_9:
	mov EAX, [EBP+arg2]
	cmp EAX, button_x + button_size
	jl  button_fail
	cmp EAX, button_x + 3*button_size
	jg button_fail
	
	mov EAX, [EBP+arg3]
	cmp EAX, button_y + 2*button_size
	jl button_fail
	cmp EAX, button_y + 3*button_size
	jg button_fail
	
	cmp con, 1
	je litera_p9x
	; cmp con, 1
	; jne cifra_p90
	
litera_p1x:
		make_text_macro 'X', area, button_x + button_size / 2 - 5, button_y + button_size / 2 - 10
		dec con
		mov bx, 0
		lea si, matrix
		mov matrix[ebx], 1
		jmp victorie


; cifra_p10:
		; make_text_macro '0', area, button_x + button_size / 2 - 5, button_y + button_size / 2 - 10
		; inc con
		; mov bx, 0
		; lea si, matrix
		; mov matrix[ebx], 0
		; jmp afisare_litere
	
litera_p2x:
		make_text_macro 'X', area, button_x + button_size / 2 - 5 + button_size, button_y + button_size / 2 - 10
		dec con
		mov bx, 1
		lea si, matrix
		mov matrix[ebx], 1
		jmp ai

; cifra_p20:
		; make_text_macro '0', area, button_x + button_size / 2 - 5 + button_size, button_y + button_size / 2 - 10
		; inc con
		; mov bx, 1
		; lea si, matrix
		; mov matrix[ebx], 0
		; jmp ai
		
litera_p3x:
		make_text_macro 'X', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 - 10
		dec con
		mov bx, 2
		lea si, matrix
		mov matrix[ebx], 1
		jmp ai

; cifra_p30:
		; make_text_macro '0', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 - 10
		; inc con
		; mov bx, 2
		; lea si, matrix
		; mov matrix[ebx], 0
		jmp ai
		
litera_p4x:
		make_text_macro 'X', area, button_x + button_size / 2 - 5, button_y + button_size / 2 + button_size - 10
		dec con
		mov bx, 3
		lea si, matrix
		mov matrix[ebx], 1
		jmp ai
	
; cifra_p40:
		; make_text_macro '0', area, button_x + button_size / 2 - 5, button_y + button_size / 2  + button_size - 10
		; inc con
		; mov bx, 3
		; lea si, matrix
		; mov matrix[ebx], 0
		; jmp ai
		
litera_p5x:
		make_text_macro 'X', area, button_x + button_size / 2 - 5 + button_size, button_y + button_size / 2 + button_size - 10
		dec con
		mov bx, 4
		lea si, matrix
		mov matrix[ebx], 1
		jmp ai
		
; cifra_p50:
		; make_text_macro '0', area, button_x + button_size / 2 - 5 + button_size, button_y + button_size / 2 + button_size - 10
		; inc con
		; mov bx, 4
		; lea si, matrix
		; mov matrix[ebx], 0
		; jmp ai
		
litera_p6x:
		make_text_macro 'X', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2+ button_size - 10
		dec con
		mov bx, 5
		lea si, matrix
		mov matrix[ebx], 1
		jmp ai

; cifra_p60:
		; make_text_macro '0', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 + button_size - 10
		; inc con
		; mov bx, 5
		; lea si, matrix
		; mov matrix[ebx], 0
		; jmp ai

litera_p7x:
		make_text_macro 'X', area, button_x + button_size / 2 - 5, button_y + button_size / 2 + 2* button_size - 10
		dec con
		mov bx, 6
		lea si, matrix
		mov matrix[ebx], 1
		jmp ai

; cifra_p70:
		; make_text_macro '0', area, button_x + button_size / 2 - 5, button_y + button_size / 2  + 2* button_size - 10
		; inc con
		; mov bx, 6
		; lea si, matrix
		; mov matrix[ebx], 0
		; jmp ai

litera_p8x:
		make_text_macro 'X', area, button_x + button_size / 2 - 5 + button_size, button_y + button_size / 2 + 2*button_size - 10
		dec con
		mov bx, 7
		lea si, matrix
		mov matrix[ebx], 1
		jmp ai
		
; cifra_p80:
		; make_text_macro '0', area, button_x + button_size / 2 - 5 + button_size, button_y + button_size / 2 + 2*button_size - 10
		; inc con
		; mov bx, 7
		; lea si, matrix
		; mov matrix[ebx], 0
		; jmp ai
		
litera_p9x:
		make_text_macro 'X', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2+ 2*button_size - 10
		dec con
		mov bx, 8
		lea si, matrix
		mov matrix[ebx], 1
		jmp ai

; cifra_p90:	
		; make_text_macro '0', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 + 2*button_size - 10
		; inc con
		; mov bx, 8
		; lea si, matrix
		; mov matrix[ebx], 0
		; jmp ai
		
ai:
	mov ebx, 0
	lea esi, matrix
	cmp matrix[ebx], 2
	jne p2
	p1:
		mov matrix[ebx], 0
		inc con
		make_text_macro '0', area, button_x + button_size / 2 - 5, button_y + button_size / 2 - 10
		jmp victorie
	
	p2:
		mov ebx, 1
		lea esi, matrix
		cmp matrix[ebx], 2
		jne p3
		
		mov matrix[ebx], 0
		inc con
		make_text_macro '0', area, button_x + button_size / 2 - 5 + button_size, button_y + button_size / 2 - 10
		jmp victorie
		
	p3:
		mov ebx, 2
		lea esi, matrix
		cmp matrix[ebx], 2
		jne p4
		
		mov matrix[ebx], 0
		inc con
		make_text_macro '0', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 - 10
		jmp victorie
	
	p4:
		mov ebx, 3
		lea esi, matrix
		cmp matrix[ebx], 2
		jne p5

		mov matrix[ebx], 0
		inc con
		make_text_macro '0', area, button_x + button_size / 2 - 5, button_y + button_size / 2  + button_size - 10
		jmp victorie
	
	p5:
		mov ebx, 4
		lea esi, matrix
		cmp matrix[ebx], 2
		jne p6

		mov matrix[ebx], 0
		inc con
		make_text_macro '0', area, button_x + button_size / 2 - 5 + button_size, button_y + button_size / 2 + button_size - 10
		jmp victorie
	
	p6:
		mov ebx, 5
		lea esi, matrix
		cmp matrix[ebx], 2
		jne p7
		
		mov matrix[ebx], 0
		inc con
		make_text_macro '0', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 + button_size - 10
		jmp victorie
	
	p7:
		mov ebx, 6
		lea esi, matrix
		cmp matrix[ebx], 2
		jne p8
	
		mov matrix[ebx], 0
		inc con
		make_text_macro '0', area, button_x + button_size / 2 - 5, button_y + button_size / 2  + 2* button_size - 10
		jmp victorie
	
	p8:
		mov ebx, 7
		lea esi, matrix
		cmp matrix[ebx], 2
		jne p9
		
		mov matrix[ebx], 0
		inc con
		make_text_macro '0', area, button_x + button_size / 2 - 5 + button_size, button_y + button_size / 2 + 2*button_size - 10
		jmp victorie
	
	p9:
		mov ebx, 8
		lea esi, matrix
		cmp matrix[ebx], 2
		jne p1
	
		mov matrix[ebx], 0
		inc con
		make_text_macro '0', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 + 2*button_size - 10
		jmp victorie
	
		
button_fail:
	jmp afisare_litere

evt_timer:
	inc counter	
	
victorie:
	verificare_linie1x:
		mov ebx, 0
		lea esi, matrix
		cmp matrix[ebx], 1
		jne verificare_coloana1x
		linie1x2:
			mov ebx, 1
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_coloana1x
		linie1x3:
			mov ebx, 2
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_coloana1x
		victorie1x:
			jmp mesaj_final_X
	
	verificare_coloana1x:
		mov ebx, 0
		lea esi, matrix
		cmp matrix[ebx], 1
		jne verificare_linie2x
		coloana1x2:
			mov ebx, 3
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_linie2x
		coloana1x3:
			mov ebx, 6
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_linie2x
		victorie2x:
			jmp mesaj_final_X
	
	verificare_linie2x:
		mov ebx, 3
		lea esi, matrix
		cmp matrix[ebx], 1
		jne verificare_coloana2x
		linie2x2:
			mov ebx, 4
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_coloana2x
		linie2x3:
			mov ebx, 5
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_coloana2x
		victorie3x:
			jmp mesaj_final_X
	
	verificare_coloana2x:
		mov ebx, 1
		lea esi, matrix
		cmp matrix[ebx], 1
		jne verificare_diagonala_principala_x
		coloana2x2:
			mov ebx, 4
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_diagonala_principala_x
		coloana2x3:
			mov ebx, 7
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_diagonala_principala_x
		victorie4x:
			jmp mesaj_final_X
		
	verificare_diagonala_principala_x:
		mov ebx, 0
		lea esi, matrix
		cmp matrix[ebx], 1
		jne verificare_linie3x
		diagonala_principala_x2:
			mov ebx, 4
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_linie3x
		iagonala_principala_x1:
			mov ebx, 8
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_linie3x
		victorie5x:
			jmp mesaj_final_X
			
	verificare_linie3x:
		mov ebx, 6
		lea esi, matrix
		cmp matrix[ebx], 1
		jne verificare_coloana3x
		linie3x2:
			mov ebx, 7
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_coloana3x
		linie3x3:
			mov ebx, 8
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_coloana3x
		victorie6x:
			jmp mesaj_final_X
	
	verificare_coloana3x:
		mov ebx, 2
		lea esi, matrix
		cmp matrix[ebx], 1
		jne verificare_diagonala_secundara_x
		coloana3x2:
			mov ebx, 5
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_diagonala_secundara_x
		coloana3x3:
			mov ebx, 8
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_diagonala_secundara_x
		victorie7x:
			jmp mesaj_final_X
	
	verificare_diagonala_secundara_x:
		mov ebx, 2
		lea esi, matrix
		cmp matrix[ebx], 1
		jne verificare_linie10
		diagonala_secundara_x2:
			mov ebx, 4
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_linie10
		diagonala_secundara_x3:
			mov ebx, 6
			lea esi, matrix
			cmp matrix[ebx], 1
			jne verificare_linie10
		victorie8x:
			jmp mesaj_final_X		
	
	verificare_linie10:
		mov ebx, 0
		lea esi, matrix
		cmp matrix[ebx], 0
		jne verificare_coloana10
		linie102:
			mov ebx, 1
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_coloana10
		linie103:
			mov ebx, 2
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_coloana10
		victorie10:
			jmp mesaj_final_0
	
	verificare_coloana10:
		mov ebx, 0
		lea esi, matrix
		cmp matrix[ebx], 0
		jne verificare_diagonala_principala_0
		coloana102:
			mov ebx, 3
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_diagonala_principala_0
		coloana103:
			mov ebx, 6
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_diagonala_principala_0
		victorie20:
			jmp mesaj_final_0
			
	verificare_diagonala_principala_0:
		mov ebx, 0
		lea esi, matrix
		cmp matrix[ebx], 0
		jne verificare_linie20
		diagonala_principala_01:
			mov ebx, 4
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_linie20
		diagonala_principala_02:
			mov ebx, 8
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_linie20
		victorie30:
			jmp mesaj_final_0
	
	verificare_linie20:
		mov ebx, 3
		lea esi, matrix
		cmp matrix[ebx], 0
		jne verificare_coloana20
		linie202:
			mov ebx, 4
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_coloana20
		linie203:
			mov ebx, 5
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_coloana20
		victorie40:
			jmp mesaj_final_0
	
	verificare_coloana20:
		mov ebx, 1
		lea esi, matrix
		cmp matrix[ebx], 0
		jne verificare_linie30
		coloana202:
			mov ebx, 4
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_linie30
		coloana203:
			mov ebx, 7
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_linie30
		victorie50:
			jmp mesaj_final_0
		
	verificare_linie30:
		mov ebx, 6
		lea esi, matrix
		cmp matrix[ebx], 0
		jne verificare_coloana30
		linie302:
			mov ebx, 7
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_coloana30
		linie303:
			mov ebx, 8
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_coloana30
		victorie60:
			jmp mesaj_final_0
		
	verificare_coloana30:
		mov ebx, 2
		lea esi, matrix
		cmp matrix[ebx], 0
		jne verificare_diagonala_secundara_0
		coloana302:
			mov ebx, 5
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_diagonala_secundara_0
		coloana303:
			mov ebx, 8
			lea esi, matrix
			cmp matrix[ebx], 0
			jne verificare_diagonala_secundara_0
		victorie70:
			jmp mesaj_final_0
			
	verificare_diagonala_secundara_0:
		mov ebx, 2
		lea esi, matrix
		cmp matrix[ebx], 0
		jne egalitate
		diagonala_secundara_02:
			mov ebx, 4
			lea esi, matrix
			cmp matrix[ebx], 0
			jne egalitate
		diagonala_secundara_03:
			mov ebx, 6
			lea esi, matrix
			cmp matrix[ebx], 0
			jne egalitate
		victorie80:
			jmp mesaj_final_0
			
	egalitate:
		mov ebx, 0
		lea esi, matrix
		cmp matrix[ebx], 2
		je afisare_litere
		
		mov ebx, 1
		lea esi, matrix
		cmp matrix[ebx], 2
		je afisare_litere
		
		mov ebx, 2
		lea esi, matrix
		cmp matrix[ebx], 2
		je afisare_litere
		
		mov ebx, 3
		lea esi, matrix
		cmp matrix[ebx], 2
		je afisare_litere
		
		mov ebx, 4
		lea esi, matrix
		cmp matrix[ebx], 2
		je afisare_litere
		
		mov ebx, 5
		lea esi, matrix
		cmp matrix[ebx], 2
		je afisare_litere
		
		mov ebx, 6
		lea esi, matrix
		cmp matrix[ebx], 2
		je afisare_litere
		
		mov ebx, 7
		lea esi, matrix
		cmp matrix[ebx], 2
		je afisare_litere
		
		mov ebx, 8
		lea esi, matrix
		cmp matrix[ebx], 2
		je afisare_litere
		
		make_text_macro 'D', area, button_x + button_size + 30, 7*button_y
		make_text_macro 'R', area, button_x + button_size + 40, 7*button_y
		make_text_macro 'A', area, button_x + button_size + 50, 7*button_y
		make_text_macro 'W', area, button_x + button_size + 60, 7*button_y
		make_text_macro ' ', area, button_x + button_size + 70, 7*button_y
		jmp reset2
		
	
mesaj_final_X:
	make_text_macro 'X', area, button_x + button_size + 30, 7*button_y
	make_text_macro ' ', area, button_x + button_size + 40, 7*button_y
	make_text_macro 'W', area, button_x + button_size + 50, 7*button_y
	make_text_macro 'O', area, button_x + button_size + 60, 7*button_y
	make_text_macro 'N', area, button_x + button_size + 70, 7*button_y
	
	inc varx
	mov ah, varx
	cmp ah, 1
	je x1
	cmp ah, 2
	je x2
	cmp ah, 3
	je x3
	cmp ah, 4
	je x4
	cmp ah, 5
	je x5
	cmp ah, 6
	je x6
	cmp ah, 7
	je x7
	cmp ah, 8
	je x8
	cmp ah, 9
	je x9
	cmp ah, 10
	je x10
	
	x1:
		make_text_macro '1', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		jmp reset2
	x2:
		make_text_macro '2', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		jmp reset2
	x3:
		make_text_macro '3', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		jmp reset2
	x4:
		make_text_macro '4', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		jmp reset2
	x5:
		make_text_macro '5', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		jmp reset2
	x6:
		make_text_macro '6', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		jmp reset2
	x7:
		make_text_macro '7', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		jmp reset2
	x8:
		make_text_macro '8', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		jmp reset2
	x9:
		make_text_macro '9', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		jmp reset2
	x10:
		make_text_macro '0', area, button_x+4*button_size + 15, button_y + 10 + button_size/2
		mov varx, 0
		jmp reset2

 mesaj_final_0:
	make_text_macro '0', area, button_x + button_size + 30, 7*button_y
	make_text_macro ' ', area, button_x + button_size + 40, 7*button_y
	make_text_macro 'W', area, button_x + button_size + 50, 7*button_y
	make_text_macro 'O', area, button_x + button_size + 60, 7*button_y
	make_text_macro 'N', area, button_x + button_size + 70, 7*button_y
	
	inc var0
	mov ah, var0
	cmp ah, 1
	je zero1
	cmp ah, 2
	je zero2
	cmp ah, 3
	je zero3
	cmp ah, 4
	je zero4
	cmp ah, 5
	je zero5
	cmp ah, 6
	je zero6
	cmp ah, 7
	je zero7
	cmp ah, 8
	je zero8
	cmp ah, 9
	je zero9
	cmp ah, 10
	je zero10
	
	zero1:
		make_text_macro '1', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		jmp reset2
	zero2:
		make_text_macro '2', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		jmp reset2
	zero3:
		make_text_macro '3', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		jmp reset2
	zero4:
		make_text_macro '4', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		jmp reset2
	zero5:
		make_text_macro '5', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		jmp reset2
	zero6:
		make_text_macro '6', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		jmp reset2
	zero7:
		make_text_macro '7', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		jmp reset2
	zero8:
		make_text_macro '8', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		jmp reset2
	zero9:
		make_text_macro '9', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		jmp reset2
	zero10:
		make_text_macro '0', area, button_x+4*button_size + 15 + button_size/2, button_y + 10 + button_size/2
		mov var0, 0
				
reset2:
	make_text_macro ' ', area, button_x + button_size / 2 - 5, button_y + button_size / 2 - 10
	make_text_macro ' ', area, button_x + button_size / 2 + button_size- 5, button_y + button_size / 2 - 10
	make_text_macro ' ', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 - 10
	make_text_macro ' ', area, button_x + button_size / 2 - 5, button_y + button_size / 2 + button_size- 10
	make_text_macro ' ', area, button_x + button_size / 2 + button_size- 5, button_y + button_size / 2 + button_size - 10
	make_text_macro ' ', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 + button_size- 10
	make_text_macro ' ', area, button_x + button_size / 2 - 5, button_y + button_size / 2 + 2*button_size- 10
	make_text_macro ' ', area, button_x + button_size / 2 + button_size- 5, button_y + button_size / 2 + 2*button_size - 10
	make_text_macro ' ', area, button_x + button_size / 2 - 5 + 2* button_size, button_y + button_size / 2 + 2*button_size- 10
	
	mov ebx, 0
	lea esi, matrix
	mov matrix[ebx], 2
	
	mov ebx, 1
	lea esi, matrix
	mov matrix[ebx], 2
	
	mov ebx, 2
	lea esi, matrix
	mov matrix[ebx], 2
	
	mov ebx, 3
	lea esi, matrix
	mov matrix[ebx], 2
	
	mov ebx, 4
	lea esi, matrix
	mov matrix[ebx], 2
	
	mov ebx, 5
	lea esi, matrix
	mov matrix[ebx], 2
	
	mov ebx, 6
	lea esi, matrix
	mov matrix[ebx], 2
	
	mov ebx, 7
	lea esi, matrix
	mov matrix[ebx], 2
	
	mov ebx, 8
	lea esi, matrix
	mov matrix[ebx], 2
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	;titlu proiect assembly(TIC TAC TOE)
	make_text_macro 'T', area, button_x + button_size/2 + 30, button_y/2
	make_text_macro 'I', area, button_x + button_size/2 + 40, button_y/2
	make_text_macro 'C', area, button_x + button_size/2 + 50, button_y/2
	
	make_text_macro 'T', area, button_x + button_size/2 + 70, button_y/2
	make_text_macro 'A', area, button_x + button_size/2 + 80, button_y/2
	make_text_macro 'C', area, button_x + button_size/2 + 90, button_y/2
	
	make_text_macro 'T', area, button_x + button_size/2 + 110, button_y/2
	make_text_macro 'O', area, button_x + button_size/2 + 120, button_y/2
	make_text_macro 'E', area, button_x + button_size/2 + 130, button_y/2
	
	;3x3 game
	line_horizontal button_x, button_y, 3*button_size, 0
	line_horizontal button_x, button_y + button_size, 3*button_size, 0
	line_vertical button_x, button_y, 3*button_size, 0
	line_vertical button_x+button_size, button_y, 3*button_size, 0
	line_vertical button_x+2*button_size, button_y, 3*button_size, 0
	line_horizontal button_x, button_y + 2*button_size, 3*button_size, 0
	line_vertical button_x+3*button_size, button_y, 3*button_size, 0
	line_horizontal button_x, button_y+3*button_size, 3*button_size, 0
	
	;scoreboard
	SCORE:
	make_text_macro 'S', area, button_x+4*button_size + 15, button_y + 10 - button_size/2
	make_text_macro 'C', area, button_x+4*button_size + 25, button_y + 10 - button_size/2
	make_text_macro 'O', area, button_x+4*button_size + 35, button_y + 10 - button_size/2
	make_text_macro 'R', area, button_x+4*button_size + 45, button_y + 10 - button_size/2
	make_text_macro 'E', area, button_x+4*button_size + 55, button_y + 10 - button_size/2
	line_horizontal button_x+4*button_size, button_y, button_size, 0 
	line_horizontal	button_x+4*button_size, button_y+button_size, button_size, 0 
	line_horizontal	button_x+4*button_size, button_y+button_size/2, button_size, 0 
	line_vertical button_x+4*button_size, button_y, button_size, 0
	line_vertical button_x+4*button_size + button_size, button_y, button_size, 0 
	line_vertical button_x+4*button_size + button_size/2, button_y, button_size, 0 
	make_text_macro 'X', area, button_x+4*button_size + 15, button_y + 10
	make_text_macro '0', area, button_x+4*button_size + 15 + button_size/2, button_y + 10
	

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
