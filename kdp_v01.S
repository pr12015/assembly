.section .data
str1: .ascii "Unesite N: \0"
str2: .ascii "Unesite string: \0"
strlen2 =.-str2
str3: .ascii "Greska u konverziji!\n\0"
str3len =.-str3
str4: .ascii "Uneli ste prazan string!\n\0"
str4len =.-str4
str5: .ascii "Broj reci sa svim malim slovima: \0"
str5len =.-str5
str6: .ascii "Izlazni string: \0"
str6len =.-str6
new_line: .ascii "\n\0"
new_line_len = 2
br_max = 5
decimalni_br: .fill br_max, 1, 0 
strlen1 = 11
str_max = 80
string: .fill str_max, 1, 0	# popuni string sa str_max elemenata velicine 1 (byte) vrednosti 0
greska: .byte 0
broj_reci: .long 0

.section .text
.globl main

###############################################
# MAKROI
#	                         
						  
.macro ispis regmem, strlen		# Macro za ispis stringa
	movl $4, %eax       
	movl $1, %ebx				
	leal \regmem, %ecx			
	movl $\strlen, %edx			
	int $0x80
.endm

###############################################

.macro unos regmem		# Macro za unos stringa
	movl $3, %eax
	movl $0, %ebx
	leal \regmem, %ecx
	movl $str_max, %edx
	int $0x80
.endm

###############################################

.macro zui dec_br	# Macro za koverziju iz znakovnog u interni
	leal \dec_br, %esi
	xorl %edx, %edx 		# indikator greske
	xorl %eax, %eax
	xorl %ebx, %ebx
	movl $10, %ecx
	
	pushl %esi
	pushl %edx
	pushl %ecx
	call dec_cifra_zui
.endm

###############################################

.macro iuz dec_br	# Macro za konverziju iz internog u znakovni
	leal \dec_br, %edi
	movl $10, %ebx
	#movl $45, %eax

	pushl %ebx	# baza
	pushl %edi	# povratna vrednost
	pushl %eax 	# vrednost za konvertovanje
	call dec_cifra_iuz
.endm

###############################################

.macro izmeni_string1 string, broj	# Macro za izmenu N reci
	leal  \string, %edx
	pushl %edx
	pushl \broj		
	call izmeni_reci
.endm # nakon izvrsavanja edx ce biti na prvom slovu ostatka recenice koja treba da se modifikuje

###############################################

#
# KRAJ MAKROA
###############################################

###############################################
# GLAVNI PROGRAM
#

main:
	ispis str1, strlen1
	unos string
	leal string, %esi	
	cmpb $10, (%esi)
	je prazan_string
	zui string
	cmpl $0, %edx
	ja greska_u_konverziji
	movl %eax, broj_reci
	
unos_stringa:
	ispis str2, strlen2
	unos string
	leal string, %esi
	cmpb $10, (%esi)
	je prazan_string1
	izmeni_string1 string, broj_reci	
	call mala_slova
	movl %eax, broj_reci
	ispis str6, str6len
	ispis string, str_max
	movl broj_reci, %eax
	iuz decimalni_br		# iuz konvertuje broj iz registra %eax u znakovni oblik i smesta ga u decimalni_br
	ispis str5, str5len
	ispis decimalni_br, br_max
	ispis new_line, new_line_len

kraj:
	movl $1, %eax
	movl $0, %ebx
	int $0x80
	
prazan_string:
	ispis str4, str4len
	jmp main
	
prazan_string1:
	ispis str4, str4len
	jmp unos_stringa

greska_u_konverziji:
	ispis str3, str3len
	jmp main
#
# KRAJ GLAVNOG PROGRAMA
###############################################	
	
###############################################
# POTPROGRAMI
#

dec_cifra_zui:	# Potprogram za konverziju iz znakovnog u interni oblik
	pushl %ebp
	movl %esp, %ebp
	movl 8(%ebp), %ecx
	movl 12(%ebp), %edx
	movl 16(%ebp), %esi	
dec_cifra1_zui:	
	movb (%esi), %bl
	cmpb $10, %bl	# Ako smo dolsi do entera ( ascii 10 ) zavrsili smo konverziju
	je kraj_dec
	cmpb $57, %bl
	ja i_greska
	andb %bl, %bl
	jz kraj_dec
	subb $'0', %bl
	mull %ecx
	jo i_greska
	addl %ebx, %eax
	incl %esi
	jmp dec_cifra1_zui
kraj_dec:
	cmpl 16(%ebp), %esi
	jne kraj1_zui
i_greska:
	incl %edx
kraj1_zui:
	movl %ebp, %esp
	popl %ebp
	ret

###############################################

dec_cifra_iuz:	# Potprogram za konverziju iz internog u znakovni
	pushl %ebp
	movl %esp, %ebp
	movl 8(%ebp), %eax
	movl 12(%ebp), %edi
	movl 16(%ebp), %ebx
dec_cifra1_iuz:
	xorl %edx, %edx
	divl %ebx
	addb $'0', %dl
	movb %dl, (%edi)
	incl %edi
	andl %eax, %eax
	jnz dec_cifra1_iuz
	movl $0, (%edi)
	decl %edi
	movl 12(%ebp), %esi
obrni:
	cmpl %edi, %esi
	jae kraj1_iuz
	movb (%esi), %ah
	movb (%edi), %al
	movb %ah, (%edi)
	movb %al, (%esi)
	decl %edi
	incl %esi
	jmp obrni

kraj1_iuz:
	movl %ebp, %esp
	popl %ebp
	ret

###############################################

izmeni_reci:			# Potprogram za modifikaciju N reci
	pushl %ebp
	movl %esp, %ebp
	pushl %eax
	pushl %ebx			# Lokalne promenljive
	pushl %ecx
	
	movl 8(%ebp), %eax
	movl 12(%ebp), %edx
	xorl %ebx, %ebx 	# Brojac izmenjenih reci
	xorl %edi, %edi 	# Indikator prelaska na novu rec
	movl broj_reci, %eax
	
petlja:
	cmpl %ebx, %eax
	je kraj_petlje		# Ako smo obradili trazen broj reci, zavrsavamo
	cmpl $10, (%edx)
	je kraj_petlje
	movb (%edx), %cl
	cmpb $'a', %cl 
	jb proveri_
	cmpb $'z', %cl
	ja separator
	cmpl $1, %edi
	jae sledece_slovo
	subb $32, %cl
	movb %cl, (%edx)
	jmp sledece_slovo	

proveri_: 
	cmpb $'_', %cl
	je sledece_slovo

proveri_A_Z:
	cmpb $'A', %cl 
	jb proveri_broj
	cmpb $'Z', %cl 
	ja separator
	cmpl $0, %edi
	je sledece_slovo
	addb $32, %cl
	movb %cl, (%edx)
	jmp sledece_slovo
	
proveri_broj:
	cmpb $'0', %cl 
	jb separator
	cmpb $'9', %cl 
	ja separator
	jmp sledece_slovo
	
separator:			# Detekcija nove reci: ako se naidje na separator kad je %edi > 0, znaci da smo zavrsili ispitivanje reci, pa povecavamo broj reci
	cmpl $0, %edi
	ja nova_rec
vrati1:
	xorl %edi, %edi  # %edi == 0 znaci da nismo na reci, vec na separatoru
	jmp sledeci_karakter
	
nova_rec:
	incl %ebx		# Inkrementuj broj reci i nastavi sa poslom
	jmp vrati1
	
sledece_slovo:
	incl %edx		
	incl %edi		# %edi > 0, trenutno smo u reci; %edi == 1, nalazimo se na pocetku reci
	jmp petlja
	
sledeci_karakter:
	incl %edx		# Ako smo na separatoru, ne menjamo %edi, zato razlicita labela
	jmp petlja
	
kraj_petlje:
	popl %ecx
	popl %ebx
	popl %eax
	movl %ebp, %esp
	popl %ebp
	ret
###############################################

mala_slova:			# Potprogram za modifikaciju ostatka stringa
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %ecx
	
	xorl %eax, %eax 		# BROJAC IZMENJENIH RECI

petlja_1:
	cmpl $10, (%edx)        # Kraj nastupa kada se naidje na ENTER ( ascii 10 )
	je kraj_petlje_1
	cmpl $1, %edi			# Ukoliko smo naisli na prvo slovo posle separatora, presli smo na novu rec
	je nova_rec_1	
vrati:
	movb (%edx), %cl		
	cmpb $'a', %cl 			#############################################################
	jb proveri_1			# Razlike u ostatku koda su minimalne u odnosu na izmeni_rec
	cmpb $'z', %cl			# Ostatak nece biti iskomentarisan
	ja separator_1			#############################################################
	jmp sledece_slovo_1		

proveri_1: 
	cmpb $'_', %cl
	je sledece_slovo_1

proveri_A_Z_1:
	cmpb $'A', %cl 
	jb proveri_broj_1
	cmpb $'Z', %cl 
	ja separator_1
	addb $32, %cl
	movb %cl, (%edx)
	jmp sledece_slovo_1
	
proveri_broj_1:
	cmpb $'0', %cl 
	jb separator_1
	cmpb $'9', %cl 
	ja separator_1
	jmp sledece_slovo_1
	
separator_1:
	xorl %edi, %edi
	jmp sledeci_karakter_1
	
nova_rec_1:
	incl %eax
	jmp vrati
	
sledece_slovo_1:
	incl %edx
	incl %edi
	jmp petlja_1
	
sledeci_karakter_1:
	incl %edx
	jmp petlja_1
	
kraj_petlje_1:
	popl %ecx
	popl %edi
	popl %ebx
	movl %ebp, %esp
	popl %ebp
	ret
