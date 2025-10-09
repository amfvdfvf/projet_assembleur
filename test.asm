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
extern XNextEvent
; external functions from stdio library (ld-linux-x86-64.so.2)
extern printf
extern exit

%define StructureNotifyMask 131072
%define KeyPressMask         1
%define ButtonPressMask      4
%define MapNotify            19
%define KeyPress             2
%define ButtonPress          4
%define Expose               12
%define ConfigureNotify      22
%define CreateNotify         16
%define QWORD                8
%define DWORD                4
%define WORD                 2
%define BYTE                 1
%define LARGEUR              800  ; Largeur en pixels de la fenêtre
%define HAUTEUR              600  ; Hauteur en pixels de la fenêtre

global main

section .bss
    display_name:    resq    1
    screen:          resd    1
    depth:           resd    1
    connection:      resd    1
    width:           resd    1
    height:          resd    1
    window:          resq    1
    gc:              resq    1
    cosinus:         resd    360
    sinus:           resd    360

section .data
    event:          times 24 dq 0
    x1:             dd 0
    x2:             dd 0
    y1:             dd 0
    y2:             dd 0
    angle:          dd 0
    demiangle:      dd 180

    ; Constantes pour la projection
    df:             dd 500.0    ; Distance focale
    Zoff:           dd 300.0    ; Offset en Z pour le zoom
    Xoff:           dd 400.0    ; Offset en X pour centrer la fenêtre
    Yoff:           dd 300.0    ; Offset en Y pour centrer la fenêtre

    ; Tableau des sommets (x, y, z) du cube
    sommets:
        dd -100.0, -100.0, -100.0  ; Sommet 0
        dd  100.0, -100.0, -100.0  ; Sommet 1
        dd  100.0,  100.0, -100.0  ; Sommet 2
        dd -100.0,  100.0, -100.0  ; Sommet 3
        dd  100.0, -100.0,  100.0  ; Sommet 4
        dd -100.0, -100.0,  100.0  ; Sommet 5
        dd -100.0,  100.0,  100.0  ; Sommet 6
        dd  100.0,  100.0,  100.0  ; Sommet 7

    ; Tableau des faces (index des sommets)
    faces:
        dd 0, 1, 2, 3    ; Face 0
        dd 1, 4, 7, 2    ; Face 1
        dd 4, 5, 6, 7    ; Face 2
        dd 5, 0, 3, 6    ; Face 3
        dd 5, 4, 1, 0    ; Face 4
        dd 3, 2, 7, 6    ; Face 5

    ; Tableau pour stocker les coordonnées 2D projetées (X', Y')
    sommets_2d: times 8 dd 0.0, 0.0  ; 8 sommets, chaque sommet a X' et Y'

section .text

calculs_trigo:
    ; Précalcule les cosinus et sinus des angles de 0 à 360°
    boucle_trigo:
        fldpi               ; st0 = PI
        fimul dword[angle]  ; st0 = PI * angle
        fidiv dword[demiangle] ; st0 = (PI * angle) / 180 = angle en radians
        fsincos             ; st0 = cos(angle), st1 = sin(angle)
        mov ecx, dword[angle]
        fstp dword[cosinus + ecx*DWORD] ; cosinus[angle] = cos(angle)
        fstp dword[sinus + ecx*DWORD]   ; sinus[angle] = sin(angle)
        inc dword[angle]
        cmp dword[angle], 360
        jbe boucle_trigo
    ret

projeter_sommets:
    ; Projette chaque sommet 3D en 2D
    mov ecx, 8              ; Nombre de sommets
    mov esi, 0              ; Index du sommet actuel
    .projeter_sommet:
        ; Charger les coordonnées (x, y, z) du sommet
        movss xmm0, [sommets + esi*12]     ; x
        movss xmm1, [sommets + esi*12 + 4] ; y
        movss xmm2, [sommets + esi*12 + 8] ; z

        ; Appliquer la formule de projection pour X'
        movss xmm3, [df]    ; xmm3 = df
        mulss xmm3, xmm0    ; xmm3 = df * x
        movss xmm4, [Zoff]  ; xmm4 = Zoff
        addss xmm4, xmm2    ; xmm4 = z + Zoff
        divss xmm3, xmm4    ; xmm3 = (df * x) / (z + Zoff)
        movss xmm5, [Xoff]  ; xmm5 = Xoff
        addss xmm3, xmm5    ; xmm3 = X' = (df * x) / (z + Zoff) + Xoff
        movss [sommets_2d + esi*8], xmm3   ; Stocker X'

        ; Appliquer la formule de projection pour Y'
        movss xmm3, [df]    ; xmm3 = df
        mulss xmm3, xmm1    ; xmm3 = df * y
        divss xmm3, xmm4    ; xmm3 = (df * y) / (z + Zoff)
        movss xmm5, [Yoff]  ; xmm5 = Yoff
        addss xmm3, xmm5    ; xmm3 = Y' = (df * y) / (z + Zoff) + Yoff
        movss [sommets_2d + esi*8 + 4], xmm3 ; Stocker Y'

        ; Passer au sommet suivant
        inc esi
        loop .projeter_sommet
    ret

dessiner_cube:
    ; Dessine les arêtes du cube projeté
    mov ecx, 6              ; Nombre de faces
    mov esi, 0              ; Index de la face actuelle
    .dessiner_face:
        ; Récupérer les 4 sommets de la face
        mov eax, [faces + esi*16]     ; Sommet 0 de la face
        mov ebx, [faces + esi*16 + 4] ; Sommet 1 de la face
        mov edx, [faces + esi*16 + 8] ; Sommet 2 de la face
        mov ebp, [faces + esi*16 + 12] ; Sommet 3 de la face

        ; Dessiner les arêtes de la face
        ; Arête 0-1
        mov rdi, qword[display_name]
        mov rsi, qword[window]
        mov rdx, qword[gc]
        mov ecx, dword[sommets_2d + eax*8]     ; X0
        mov r8d, dword[sommets_2d + eax*8 + 4] ; Y0
        mov r9d, dword[sommets_2d + ebx*8]     ; X1
        push qword[sommets_2d + ebx*8 + 4]     ; Y1
        call XDrawLine
        add rsp, 8

        ; Arête 1-2
        mov rdi, qword[display_name]
        mov rsi, qword[window]
        mov rdx, qword[gc]
        mov ecx, dword[sommets_2d + ebx*8]     ; X0
        mov r8d, dword[sommets_2d + ebx*8 + 4] ; Y0
        mov r9d, dword[sommets_2d + edx*8]     ; X1
        push qword[sommets_2d + edx*8 + 4]     ; Y1
        call XDrawLine
        add rsp, 8

        ; Arête 2-3
        mov rdi, qword[display_name]
        mov rsi, qword[window]
        mov rdx, qword[gc]
        mov ecx, dword[sommets_2d + edx*8]     ; X0
        mov r8d, dword[sommets_2d + edx*8 + 4] ; Y0
        mov r9d, dword[sommets_2d + ebp*8]     ; X1
        push qword[sommets_2d + ebp*8 + 4]     ; Y1
        call XDrawLine
        add rsp, 8

        ; Arête 3-0
        mov rdi, qword[display_name]
        mov rsi, qword[window]
        mov rdx, qword[gc]
        mov ecx, dword[sommets_2d + ebp*8]     ; X0
        mov r8d, dword[sommets_2d + ebp*8 + 4] ; Y0
        mov r9d, dword[sommets_2d + eax*8]     ; X1
        push qword[sommets_2d + eax*8 + 4]     ; Y1
        call XDrawLine
        add rsp, 8

        ; Passer à la face suivante
        inc esi
        loop .dessiner_face
    ret

;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################
main:
    call calculs_trigo      ; Précalcul des cosinus et sinus

    ; Sauvegarde du registre de base pour préparer les appels à printf
    push rbp
    mov rbp, rsp

    ; Ouvre le display par défaut
    xor rdi, rdi            ; rdi = 0 (NULL)
    call XOpenDisplay       ; Appel de XOpenDisplay
    test rax, rax           ; Vérifie si l'ouverture a réussi
    jz closeDisplay         ; Si échec, ferme le display et quitte
    mov [display_name], rax ; Stocke le display ouvert

    ; Récupère la fenêtre racine (root window) du display
    mov rdi, qword[display_name]
    xor esi, esi            ; esi = 0 (écran par défaut)
    call XRootWindow        ; Appel de XRootWindow
    mov rbx, rax            ; Stocke la root window dans rbx

    ; Création d'une fenêtre simple
    mov rdi, qword[display_name]
    mov rsi, rbx            ; parent = root window
    mov rdx, 10             ; position x de la fenêtre
    mov rcx, 10             ; position y de la fenêtre
    mov r8, LARGEUR         ; largeur de la fenêtre
    mov r9, HAUTEUR         ; hauteur de la fenêtre
    push 0x000000           ; couleur du bord (noir)
    push 0xFFFFFF           ; couleur de fond (blanc)
    push 1                  ; épaisseur du bord
    call XCreateSimpleWindow
    mov qword[window], rax  ; Stocke l'identifiant de la fenêtre

    ; Sélection des événements à écouter sur la fenêtre
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, StructureNotifyMask + KeyPressMask
    call XSelectInput

    ; Affichage (mapping) de la fenêtre
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    call XMapWindow

    ; Création du contexte graphique (GC)
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    xor rdx, rdx            ; Aucun masque particulier
    xor rcx, rcx            ; Aucune valeur particulière
    call XCreateGC
    mov qword[gc], rax      ; Stocke le GC dans la variable gc

    ; Définir la couleur du GC (noir)
    mov rdi, qword[display_name]
    mov rsi, qword[gc]
    mov edx, 0x000000       ; Couleur noire
    call XSetForeground

    ; Boucle de gestion des événements
    boucle:
        mov rdi, qword[display_name]
        cmp rdi, 0         ; Vérifie que le display est toujours valide
        je closeDisplay

        mov rsi, event     ; Passe l'adresse de la structure d'événement
        call XNextEvent    ; Attend et récupère le prochain événement

        cmp dword[event], ConfigureNotify
        je dessin
        cmp dword[event], KeyPress
        je closeDisplay
        jmp boucle

    ;#########################################
    ;#       DEBUT DE LA ZONE DE DESSIN       #
    ;#########################################
    dessin:
        call projeter_sommets  ; Projette les sommets 3D en 2D
        call dessiner_cube     ; Dessine le cube projeté

        ; Rafraîchir l'affichage
        mov rdi, qword[display_name]
        call XFlush
        jmp boucle

    ;#########################################
    ;#       FIN DE LA ZONE DE DESSIN         #
    ;#########################################

    closeDisplay:
        mov rax, qword[display_name]
        mov rdi, rax
        call XCloseDisplay
        xor rdi, rdi
        call exit
