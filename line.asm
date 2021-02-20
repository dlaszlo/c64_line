                .cpu "6502"
                .enc "screen"

VIC_MEM_SCHEMA    = #%00011010          ; Bitmap is at $2000, Screenmem is at $0000; Charmem is at $0800

VIC_BANK1         = #%00000011          ; Bank 0

VIC_BASE_ADDRESS1 = $0000
BITMAP_ADDRESS1   = VIC_BASE_ADDRESS1 + $2000
COLOR1_ADDRESS1   = VIC_BASE_ADDRESS1 + $0400
COLOR2_ADDRESS    = $d800

PLOTADDR          = $02

.include "colors.inc"


COLOR0            = BLACK
COLOR1            = WHITE
COLOR2            = LIGHT_BLUE
COLOR3            = BLUE

*               = $4000

                jsr     init_vic

loop
                jsr     clearscreen

                ldx     #0
                stx     x0
                ldy     #0
                sty     y0
                ldx     #0
                stx     x1
                ldy     #199
                sty     y1
                .for i := 0, i < 160, i += 1
                jsr     line
                inc     x1
                .next
                dec     x1
                .for i := 0, i < 200, i += 1
                jsr     line
                dec     y1
                .next
                inc     y1

                jsr     clearscreen

                ldx     #0
                stx     x0
                ldy     #199
                sty     y0
                ldx     #0
                stx     x1
                ldy     #0
                sty     y1
                .for i := 0, i < 160, i += 1
                jsr     line
                inc     x1
                .next
                dec     x1
                .for i := 0, i < 200, i += 1
                jsr     line
                inc     y1
                .next
                dec     y1

                jsr     clearscreen

                ldx     #159
                stx     x0
                ldy     #199
                sty     y0
                ldx     #0
                stx     x1
                ldy     #199
                sty     y1
                .for i := 0, i < 200, i += 1
                jsr     line
                dec     y1
                .next
                inc     y1
                .for i := 0, i < 160, i += 1
                jsr     line
                inc     x1
                .next
                dec     x1

                jsr     clearscreen

                ldx     #159
                stx     x0
                ldy     #0
                sty     y0
                ldx     #0
                stx     x1
                ldy     #0
                sty     y1
                .for i := 0, i < 200, i += 1
                jsr     line
                inc     y1
                .next
                dec     y1
                .for i := 0, i < 160, i += 1
                jsr     line
                inc     x1
                .next
                dec     x1

                jmp     loop


; ===========================
; Képpont rajzolása
; Paraméterek: cx, cy
; ===========================

plot            
                sta     aa1 + 1      ; plot (cx, cy)
                stx     xx1 + 1
                sty     yy1 + 1
                ldx     cx
                ldy     cy
                clc                
                lda     ytablelow1, y
                adc     xtablelow, x
                sta     PLOTADDR
                lda     ytablehigh1, y
                adc     xtablehigh, x
                sta     PLOTADDR + 1
                ldy     #$00
                lda     (PLOTADDR), y
                ora     mask, x
                sta     (PLOTADDR), y
yy1             ldy     #$00
xx1             ldx     #$00
aa1             lda     #$00
                rts

;
; \ 1|2 /
;  \ | /
; 8 \|/ 3
; ---+----    
; 7 /|\ 4
;  / | \
; / 6|5 \
;
; DX > DY | Y | X | Routine
;---------+---+---+----------
;       0 | 0 | 0 | line4
;       0 | 0 | 1 | line7
;       0 | 1 | 0 | line3
;       0 | 1 | 1 | line8
;       1 | 0 | 0 | line5
;       1 | 0 | 1 | line6
;       1 | 1 | 0 | line2
;       1 | 1 | 1 | line1

.align 256
lineaddr
        .word line4
        .word line7
        .word line3
        .word line8
        .word line5
        .word line6
        .word line2
        .word line1

lineptr .byte 0
x0      .byte 0
y0      .byte 0
x1      .byte 0
y1      .byte 0
cx      .byte 0
cy      .byte 0
dx      .byte 0
dy      .byte 0

line            lda     #$00
                sta     lineptr

                lda     x1          ; a = x1 - x0
                sec
                sbc     x0
                bcs     +           ; a = abs(a)
                eor     #$ff        
                clc
                adc     #$00
                inc     lineptr
+               sta     dx          ; dx = a

                lda     y1          ; a = y1 - y0
                sec
                sbc     y0
                bcs     +           ; a = abs(a)
                eor     #$ff
                clc
                adc     #$00
                inc     lineptr
                inc     lineptr
+               sta     dy

                lda     dx
                cmp     dy
                bcs     +
                lda     #$4
                ora     lineptr
                sta     lineptr
+

                lda     x0          ; cx = x0 (kezdő x pont, ezt növeljük vagy csökkentjük)
                sta     cx
                lda     y0          ; cy = y0 (kezdő y pont, ezt növeljük vagy csökkentjük)
                sta     cy                

                lda     lineptr
                shl
                tax


                lda     lineaddr + 1, x
                sta     linejmp + 2
                lda     lineaddr, x
                sta     linejmp + 1

linejmp:        jmp     line4

line0           rts


;
;\ 1|2 /
; \ | /
;8 \|/ 3
;---+----    
;7 /|\ 4
; / | \
;/ 6|5 \
;
line1           lda     dy
                tay                 ; y = dy + 1, a = dy / 2
                iny
                shr
-               jsr     plot
                clc                 ; a = a + dx
                adc     dx
                bcs     +
                cmp     dy          ; if a >= dy then
                bcc     ++          ;   a = a - dy
+               sec                 ;   cx--
                sbc     dy
                dec     cx          ; endif
+               dec     cy          ; cy--
                dey
                bne     -
                rts

;
;\ 1|2 /
; \ | /
;8 \|/ 3
;---+----    
;7 /|\ 4
; / | \
;/ 6|5 \
;
line2           lda     dy
                tay                 ; y = dy + 1, a = dy / 2
                iny
                shr
-               jsr     plot
                clc                 ; a = a + dx
                adc     dx
                bcs     +
                cmp     dy          ; if a >= dy then
                bcc     ++          ;   a = a - dy
+               sec                 ;   cx++
                sbc     dy
                inc     cx          ; endif
+               dec     cy          ; cy--
                dey
                bne     -
                rts

;
;\ 1|2 /
; \ | /
;8 \|/ 3
;---+----    
;7 /|\ 4
; / | \
;/ 6|5 \
;
line3           lda     dx
                tax                 ; x = dx + 1, a = dx / 2
                inx
                shr
-               jsr     plot
                clc                 ; a = a + dy
                adc     dy
                bcs     +
                cmp     dx          ; if a >= dx then
                bcc     ++          ;   a = a - dx
+               sec                 ;   cy--
                sbc     dx
                dec     cy          ; endif
+               inc     cx          ; cx++
                dex
                bne     -
                rts

;
;\ 1|2 /
; \ | /
;8 \|/ 3
;---+----    
;7 /|\ 4
; / | \
;/ 6|5 \
;
line4           lda     dx
                tax                 ; x = dx + 1, a = dx / 2
                inx
                shr
-               jsr     plot
                clc                 ; a = a + dy
                adc     dy
                bcs     +
                cmp     dx          ; if a >= dx then
                bcc     ++          ;   a = a - dx
+               sec                 ;   cy++
                sbc     dx
                inc     cy          ; endif
+               inc     cx          ; cx++
                dex
                bne     -
                rts

;
;\ 1|2 /
; \ | /
;8 \|/ 3
;---+----    
;7 /|\ 4
; / | \
;/ 6|5 \
;
line5           lda     dy
                tay                 ; y = dy + 1, a = dy / 2
                iny
                shr
-               jsr     plot
                clc                 ; a = a + dx
                adc     dx
                bcs     +
                cmp     dy          ; if a >= dy then
                bcc     ++          ;   a = a - dy
+               sec                 ;   cx++
                sbc     dy
                inc     cx          ; endif
+               inc     cy          ; cy++
                dey
                bne     -
                rts


;
;\ 1|2 /
; \ | /
;8 \|/ 3
;---+----    
;7 /|\ 4
; / | \
;/ 6|5 \
;
line6           lda     dy
                tay                 ; y = dy + 1, a = dy / 2
                iny
                shr
-               jsr     plot
                clc                 ; a = a + dx
                adc     dx
                bcs     +
                cmp     dy          ; if a >= dy then
                bcc     ++          ;   a = a - dy
+               sec                 ;   cx--
                sbc     dy
                dec     cx          ; endif
+               inc     cy          ; cy++
                dey
                bne     -
                rts

;
;\ 1|2 /
; \ | /
;8 \|/ 3
;---+----    
;7 /|\ 4
; / | \
;/ 6|5 \
;
line7           lda     dx
                tax                 ; x = dx + 1, a = dx / 2
                inx
                shr
-               jsr     plot
                clc                 ; a = a + dy
                adc     dy
                bcs     +
                cmp     dx          ; if a >= dx then
                bcc     ++          ;   a = a - dx
+               sec                 ;   cy++
                sbc     dx
                inc     cy          ; endif
+               dec     cx          ; cx--
                dex
                bne     -
                rts

;
;\ 1|2 /
; \ | /
;8 \|/ 3
;---+----    
;7 /|\ 4
; / | \
;/ 6|5 \
;
line8           lda     dx
                tax                 ; x = dx + 1, a = dx / 2
                inx
                shr
-               jsr     plot
                clc                 ; a = a + dy
                adc     dy
                bcs     +
                cmp     dx          ; if a >= dx then
                bcc     ++          ;   a = a - dx
+               sec                 ;   cy--
                sbc     dx
                dec     cy          ; endif
+               dec     cx          ; cx--
                dex
                bne     -
                rts

; ===========================
; VIC inicializálása
; ===========================
init_vic        
                lda     #$0b
                sta     $d011

                jsr     setup_color
                jsr     clearscreen

                ; VIC mem schema
                lda     VIC_MEM_SCHEMA
                sta     $d018

                ; Multicolor bitmap mode
                lda     #$3b
                sta     $d011
                lda     #$18
                sta     $d016
				
                ; Select VIC bank
                lda     $dd00
                and     #%11111100      ; VIC bank mask
                ora     VIC_BANK1
                sta     $dd00
				
                rts

; ===========================
; Színek beállítása
; ===========================
setup_color     
                ; Background color
;                lda     #(COLOR0)
;                sta     $d020
;                sta     $d021

                ; Foreground color
                lda     #$00
                tax
-               lda     #((COLOR3 << 4) + COLOR2)
                .for i := 0, i < $400, i += $100
                sta     COLOR1_ADDRESS1 + i, x
                .next
                lda     #(COLOR1)
                .for i := 0, i < $400, i += $100
                sta     COLOR2_ADDRESS + i, x
                .next
                dex
                beq     +
                jmp     -
+               rts

; ===========================
; Képernyő törlése
; ===========================
clearscreen     lda     #$00
                tax
-               lda     #$00
                .for i := 0, i < $2000, i += $100
                sta     BITMAP_ADDRESS1 + i, x
                .next
                dex
                beq     +
                jmp     -
+               rts

.include "tables.inc"

