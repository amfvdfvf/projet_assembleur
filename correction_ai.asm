; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1
%define	LARGEUR 400	; largeur en pixels de la fenêtre
%define HAUTEUR 400	; hauteur en pixels de la fenêtre

global main

section .bss
display_name:	resq	1
screen:		resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1

cosinus:	resd	360
sinus:	resd	360


section .data

event:		times	24 dq 0

x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0

angle:	dd	0
demiangle:	dd	180

sommets:
    dd 0.0,52.573195,-85.0652164072 ; 0
    dd 0.0,-52.573195,-85.0652164072 ; 1
    dd 85.0652164072,0.0,-52.573195 ; 2
    dd 85.0652164072,0.0,52.573195 ; 3
    dd 0.0,52.573195,85.0652164072 ; 4
    dd 0.0,-52.573195,85.0652164072 ; 5
    dd -85.0652164072,0.0,52.573195 ; 6
    dd -85.0652164072,0.0,-52.573195 ; 7
    dd 52.573195,85.0652164072,0.0 ; 8
    dd -52.573195,85.0652164072,0.0 ; 9
    dd -52.573195,-85.0652164072,0.0 ; 10
    dd 52.573195,-85.0652164072,0.0 ; 11

faces:
    dd 9,8,0,9
    dd 8,2,0,8
    dd 8,3,2,8
    dd 8,4,3,8
    dd 8,9,4,8
    dd 4,9,6,4
    dd 6,9,7,6
    dd 9,0,7,9
    dd 11,10,1,11
    dd 2,11,1,2
    dd 2,3,11,2
    dd 3,5,11,3
    dd 5,10,11,5
    dd 5,6,10,5
    dd 6,7,10,6
    dd 7,1,10,7
    dd 1,7,0,1
    dd 2,1,0,2
    dd 4,5,3,4
    dd 4,6,5,5

tab2d: times 24 dd 0

df: dd 400.0
zoff: dd 400.0
xoff: dd 200.0
yoff: dd 200.0

affxy: db "(%hd)",0,10

tabx: times 12 dd 1
taby: times 12 dd 1

x10 : dd 0
y10 : dd 0

x12 : dd 0
y12 : dd 0

x3 : dd 0
y3 : dd 0

x10y12 : dd 0
y10X12 : dd 0

section .text

calculs_trigo:		; cette fonction précalcule les cosinus et sinus des angles de 0 à 360°
					; et les sauvegarde dans les tableaux cosinus et sinus.
	boucle_trigo:
		fldpi	; st0=PI
		fimul dword[angle]	; st0=PI*angle
		fidiv dword[demiangle]	; st0=(PI*angle)/demi=angle en radians
		fsincos		; st0=cos(angleradian), st1=sin(angleradian)
		mov ecx,dword[angle]
		fstp dword[cosinus+ecx*DWORD] ; cosinus[REAL8*angle]=st0=cos(angle) puis st0=sin(angle)
		fstp dword[sinus+ecx*DWORD] ; sinus[REAL8*angle]=st0=sin(angle) puis st0 vide
		inc dword[angle]
		cmp dword[angle],360
		jbe boucle_trigo
ret
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
 
 call calculs_trigo	; précalcul des cosinus et sinus
 
    ; Sauvegarde du registre de base pour préparer les appels à printf
    push    rbp
    mov     rbp, rsp

    ; Récupère le nom du display par défaut (en passant NULL)
    xor     rdi, rdi          ; rdi = 0 (NULL)
    call    XDisplayName      ; Appel de la fonction XDisplayName
    ; Vérifie si le display est valide
    test    rax, rax          ; Teste si rax est NULL
    jz      closeDisplay      ; Si NULL, ferme le display et quitte

    ; Ouvre le display par défaut
    xor     rdi, rdi          ; rdi = 0 (NULL pour le display par défaut)
    call    XOpenDisplay      ; Appel de XOpenDisplay
    test    rax, rax          ; Vérifie si l'ouverture a réussi
    jz      closeDisplay      ; Si échec, ferme le display et quitte

    ; Stocke le display ouvert dans la variable globale display_name
    mov     [display_name], rax

    ; Restaure le cadre de pile sauvegardé
    mov     rsp, rbp
    pop     rbp

    ; Récupère la fenêtre racine (root window) du display
    mov     rdi,qword[display_name]   ; Place le display dans rdi
    mov     esi,dword[screen]         ; Place le numéro d'écran dans esi
    call XRootWindow                ; Appel de XRootWindow pour obtenir la fenêtre racine
    mov     rbx,rax               ; Stocke la root window dans rbx

    ; Création d'une fenêtre simple
    mov     rdi,qword[display_name]   ; display
    mov     rsi,rbx                   ; parent = root window
    mov     rdx,10                    ; position x de la fenêtre
    mov     rcx,10                    ; position y de la fenêtre
    mov     r8,LARGEUR                ; largeur de la fenêtre
    mov     r9,HAUTEUR           	; hauteur de la fenêtre
    push 0x000000                     ; couleur du fond (noir, 0x000000)
    push 0x00FF00                     ; couleur de fond (vert, 0x00FF00)
    push 1                          ; épaisseur du bord
    call XCreateSimpleWindow        ; Appel de XCreateSimpleWindow
    mov qword[window],rax           ; Stocke l'identifiant de la fenêtre créée dans window

    ; Sélection des événements à écouter sur la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,131077                 ; Masque d'événements (ex. StructureNotifyMask + autres)
    call XSelectInput

    ; Affichage (mapping) de la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    call XMapWindow

    ; Création du contexte graphique (GC) avec vérification d'erreur
    mov rdi, qword[display_name]
    test rdi, rdi                ; Vérifie que display n'est pas NULL
    jz closeDisplay

    mov rsi, qword[window]
    test rsi, rsi                ; Vérifie que window n'est pas NULL
    jz closeDisplay

    xor rdx, rdx                 ; Aucun masque particulier
    xor rcx, rcx                 ; Aucune valeur particulière
    call XCreateGC               ; Appel de XCreateGC pour créer le contexte graphique
    test rax, rax                ; Vérifie la création du GC
    jz closeDisplay              ; Si échec, quitte
    mov qword[gc], rax           ; Stocke le GC dans la variable gc
	
boucle: ; Boucle de gestion des événements
    mov     rdi, qword[display_name]
    cmp     rdi, 0              ; Vérifie que le display est toujours valide
    je      closeDisplay        ; Si non, quitte
    mov     rsi, event          ; Passe l'adresse de la structure d'événement
    call    XNextEvent          ; Attend et récupère le prochain événement

    cmp     dword[event], ConfigureNotify ; Si l'événement est ConfigureNotify (ex: redimensionnement)
    je      dessin                        ; Passe à la phase de dessin

    cmp     dword[event], KeyPress        ; Si une touche est pressée
    je      closeDisplay                  ; Quitte le programme
    jmp     boucle                        ; Sinon, recommence la boucle


;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:

;couleur de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0xFF0000
call XSetForeground
mov dword[x1],50
mov dword[y1],50
mov dword[x2],200
mov dword[y2],350
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]
mov r8d,dword[y1]
mov r9d,dword[x2]
push qword[y2]
call XDrawLine
pop rax              ; 

;couleur de la ligne 2
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x00FF00
call XSetForeground
mov dword[x1],50
mov dword[y1],350
mov dword[x2],200
mov dword[y2],50
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]
mov r8d,dword[y1]
mov r9d,dword[x2]
push qword[y2]
call XDrawLine
pop rax              ; 

;couleur de la ligne 3
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x00FFFF
call XSetForeground
mov dword[x1],275
mov dword[y1],50
mov dword[x2],275
mov dword[y2],350
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]
mov r8d,dword[y1]
mov r9d,dword[x2]
push qword[y2]
call XDrawLine
pop rax              ; 

;couleur de la ligne 4
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0xFF00FF
call XSetForeground
mov dword[x1],350
mov dword[y1],50
mov dword[x2],350
mov dword[y2],350
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]
mov r8d,dword[y1]
mov r9d,dword[x2]
push qword[y2]
call XDrawLine
pop rax              ; 

; Ligne 5
mov dword[x1],100
mov dword[y1],100
mov dword[x2],300
mov dword[y2],100
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]
mov r8d,dword[y1]
mov r9d,dword[x2]
push qword[y2]
call XDrawLine
pop rax 

mov dword[x1],100
mov dword[y1],100
mov dword[x2],150
mov dword[y2],150
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]
mov r8d,dword[y1]
mov r9d,dword[x2]
push qword[y2]
call XDrawLine
pop rax 

mov dword[x1],300
mov dword[y1],100
mov dword[x2],350
mov dword[y2],150
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]
mov r8d,dword[y1]
mov r9d,dword[x2]
push qword[y2]
call XDrawLine
pop rax                       ; 

mov dword[x1],150
mov dword[y1],150
mov dword[x2],350
mov dword[y2],150
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]
mov r8d,dword[y1]
mov r9d,dword[x2]
push qword[y2]
call XDrawLine
pop rax

; test boucle 3d to 2d 


mov rsi, sommets ; tab 3d
mov rdi, tab2d 
mov rcx,12 

loop_1:
    
    cmp rcx, 0
    jle etape_aff

    movss xmm0, [rsi]      ; X
    movss xmm1, [rsi+4]    ; Y
    movss xmm2, [rsi+8]    ; Z

    ; charger les valeurs
    movss xmm3, [df]        
    movss xmm4, [zoff]     
    movss xmm5, [xoff]    
    movss xmm6, [yoff]    

    movss xmm7, xmm2     
    addss xmm7, xmm4       ; Z + zoff
    mulss xmm0, xmm3       ; X * df
    divss xmm0, xmm7       ; (X * df) / (Z + zoff)
    addss xmm0, xmm5       ; + xoff
    
    ; Pour y_screen :
    mulss xmm1, xmm3       ; Y * df
    divss xmm1, xmm7       ; (Y * df) / (Z + zoff)
    addss xmm1, xmm6       ; + yoff

    movss [rdi], xmm0     
    movss [rdi+4], xmm1    

    add rsi, 12
    add rdi, 8

    dec rcx

    jmp loop_1

etape_aff:
; Affichage des faces du dodécaèdre
; Chaque face a 4 sommets : on trace les 4 arêtes (lignes entre points consécutifs)

mov r12, 0              ; compteur de faces (0 à 19)

boucle_faces:
    cmp r12, 20         ; 20 faces au total
    jge fin

    ; Calculer l'offset dans le tableau faces (chaque face = 4 indices de 4 octets = 16 octets)
    mov rax, r12
    shl rax, 4          ; multiplier par 16 (4 indices * 4 octets)
    lea rbx, [faces + rax]  ; rbx pointe sur la face actuelle

    ; Récupérer les 4 indices de sommets de cette face
    mov r8d, [rbx]      ; sommet 0
    mov r9d, [rbx+4]    ; sommet 1
    mov r10d, [rbx+8]   ; sommet 2
    mov r11d, [rbx+12]  ; sommet 3

    call tracer_ligne_entre_sommets

    ; Tracer ligne entre sommet 1 et sommet 2
    mov r8d, r9d
    mov r9d, r10d
    call tracer_ligne_entre_sommets

    ; Tracer ligne entre sommet 2 et sommet 3
    mov r8d, r10d
    mov r9d, r11d
    call tracer_ligne_entre_sommets

    ; Tracer ligne entre sommet 3 et sommet 0 (fermer la face)
    mov r8d, r11d
    mov r9d, [rbx]      ; retour au sommet 0
    call tracer_ligne_entre_sommets

    inc r12
    jmp boucle_faces

tracer_ligne_entre_sommets:
    ; r8d = indice du premier sommet
    ; r9d = indice du deuxième sommet
    ; Récupère les coordonnées 2D et trace la ligne
    
    push r8
    push r9
    push r10
    push r11
    push r12
    
    ; Coordonnées du premier point
    mov rax, r8
    shl rax, 3          ; * 8 (chaque point 2D = 2 floats de 4 octets)
    movss xmm0, [tab2d + rax]       ; x1
    movss xmm1, [tab2d + rax + 4]   ; y1
    
    ; Coordonnées du deuxième point
    mov rax, r9
    shl rax, 3
    movss xmm2, [tab2d + rax]       ; x2
    movss xmm3, [tab2d + rax + 4]   ; y2
    
    ; Convertir en entiers
    cvttss2si ecx, xmm0   ; x1
    cvttss2si r8d, xmm1   ; y1
    cvttss2si r9d, xmm2   ; x2
    cvttss2si eax, xmm3   ; y2
    
    ; avant il faut proen les point x3 et y3
    ;recup face r10d mais dasn notre codeil faut faire un plus
    mov rax, r10
    shl rax, 3
    movss xmm4, [tab2d + rax]       ; x3
    movss xmm5, [tab2d + rax + 4]   ; y3

    cvttss2si word[x3], xmm4   ; x3
    cvttss2si word[y3], [xmm5]   ; y3

    ; x10 = x0-x1
    mov r15, rcx
    sub r15, r9
    mov word[x10], r15

    ; y10 = y0-y1
    mov r15, r8
    sub r15, rax
    mov word[y10], r15

    ;x12 = x2-x1
    mov r15, word[x3]
    sub r15, r9
    mov word[x12], r15

    ;y12 = y2-y1
    mov r15, word[y3]
    sub r15, rax
    mov word[y12], r15

    ;(x10*y12)-(y10*x12)

    ;x10*y12
    movsx r15, word[x10]
    movsx r14, word[y12]
    imul r15, r14
    mov word[x10y12]

    ;y10*x12
    movsx r15, word[y10]
    movsx r14, word[x12]
    imul r15, r14
    mov word[y10X12]

    ;faire la soustrzction

    mov r14, word[y10X12]
    mov r15, word[x10y12]
    sub r14, r15

    cmp r14, 0
    jle jump_a_la_boucle_for

    ; ecrire ici le code pour les face cacher
    
    ; Appeler XDrawLine
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    push rax
    call XDrawLine
    add rsp, 8
    
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    ret


fin:
mov esi,0 
jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
