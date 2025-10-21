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

x10 : dd 0
y10 : dd 0

x12 : dd 0
y12 : dd 0

x3 : dd 0
y3 : dd 0

x10y12 : dd 0
y10X12 : dd 0


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

df: dd 700.0
zoff: dd 400.0
xoff: dd 200.0
yoff: dd 200.0

affxy: db "(%hd)",0,10

tabx: times 12 dd 1
taby: times 12 dd 1

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
     ; 

;couleur de la ligne 3
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x00FFFF
call XSetForeground

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
                     ; 


; Boucle 3d to 2d 


mov rsi, sommets ; tab 3d
mov rdi, tab2d ; tab resutl 2d
mov rcx,12 ; conteur 12 point

loop_1:
    
    cmp rcx, 0
    jle etape_aff

    movss xmm0, [rsi] ; x
    movss xmm1, [rsi+4] ; y
    movss xmm2, [rsi+8] ; z

    ; charger les valeur

    movss xmm3, [df] ; df
    movss xmm4, [zoff] ;zoff
    movss xmm5, [xoff];xoff
    movss xmm6, [yoff];yoff
    ; pour x
    addss xmm2, xmm4

    mulss xmm0, xmm3

    divss xmm0, xmm2

    addss xmm0, xmm5
    ; pour y 
    addss xmm2, xmm4 ; redondance pas utilme mais pour mieux comprendre si

    mulss xmm1, xmm3

    divss xmm1, xmm2

    addss xmm1, xmm6

    movss [rdi], xmm0 ; tab2d = x
    movss [rdi+4], xmm1 ; tab2d = y

    add rsi, 12
    add rdi, 8

    dec rcx

    jmp loop_1

etape_aff:
;faire le code pour affihcer le patangoen avec les coodonée en 2d stp

;tesssssssssssssssssssssssssssssssssssssssss


; Dessiner les arêtes des faces (20 faces, 4 sommets chacune)
xor r13d, r13d                 ; face index = 0
for_loop_aff1:
    cmp r13d, 20
    jge ici

    ; r10 = adresse base de la face courante (4 dwords)
    mov     r10, faces
    mov     eax, r13d
    imul    rax, 16
    add     r10, rax

    ; Back-face culling calculé une fois par face, avec v0,v1,v2 projetés
    mov     eax, dword [r10]         ; v0
    imul    rax, 8
    movss   xmm0, dword [tab2d + rax]       ; x0
    movss   xmm1, dword [tab2d + rax + 4]   ; y0

    mov     ecx, dword [r10+4]       ; v1
    imul    rcx, 8
    movss   xmm2, dword [tab2d + rcx]       ; x1
    movss   xmm3, dword [tab2d + rcx + 4]   ; y1

    mov     edx, dword [r10+8]       ; v2
    imul    rdx, 8
    movss   xmm4, dword [tab2d + rdx]       ; x2
    movss   xmm5, dword [tab2d + rdx + 4]   ; y2

    ; cross = (x1-x0)*(y2-y0) - (y1-y0)*(x2-x0)
    movaps  xmm6, xmm2
    subss   xmm6, xmm0
    movaps  xmm7, xmm3
    subss   xmm7, xmm1
    movaps  xmm2, xmm4
    subss   xmm2, xmm0
    movaps  xmm3, xmm5
    subss   xmm3, xmm1

    movaps  xmm4, xmm6
    mulss   xmm4, xmm3
    movaps  xmm5, xmm7
    mulss   xmm5, xmm2
    subss   xmm4, xmm5
    xorps   xmm5, xmm5 
    comiss  xmm4, xmm5
    jbe     next_face            

    ; Face visible: boucler sur les 4 arêtes
    xor r12d, r12d             ; edge index 0..3
for_loop_aff2:
    cmp r12d, 4
    jge next_face

    ; v0 = faces[face*4 + r12]
    mov     eax, r12d
    mov     r11d, dword [r10 + rax*4]

    ; v1 = faces[face*4 + ((r12+1) & 3)]
    lea     eax, [r12d+1]
    and     eax, 3
    mov     r14d, dword [r10 + rax*4]

    ; lire coords projetées
    movss   xmm0, dword [tab2d + r11*8]       ; x1
    movss   xmm1, dword [tab2d + r11*8 + 4]   ; y1
    movss   xmm2, dword [tab2d + r14*8]       ; x2
    movss   xmm3, dword [tab2d + r14*8 + 4]   ; y2

    ; floats -> ints
    cvttss2si ecx, xmm0       ; x1
    cvttss2si r8d, xmm1       ; y1
    cvttss2si r9d, xmm2       ; x2
    cvttss2si r15d, xmm3      ; y2 (ne pas écraser r10 qui pointe la face)

    ; appel XDrawLine(display, window, gc, x1, y1, x2, y2)
    mov     rdi, qword [display_name]
    mov     rsi, qword [window]
    mov     rdx, qword [gc]
    push    r15                ; y2 (7e arg sur la pile)
    call    XDrawLine
    add     rsp, 8

    inc r12d
    jmp for_loop_aff2

next_face:
    inc r13d
    jmp for_loop_aff1
;tessssssssssssssssssssssssssssssssssssssss

ici:
 
mov rcx, 12

llop_aff_test:
    cmp rcx, 0
    jl fin
    mov rdi, affxy
    mov rsi, rcx
    mov rax, 0
    call printf
    dec rcx
    jmp llop_aff_test


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
