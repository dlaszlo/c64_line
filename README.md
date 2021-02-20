# C64 vonalhúzó rutin


```
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
                tay                 ; y = dy + 1
                iny
                shr                 ; a = dy / 2
-               jsr     plot
                clc                 ; a = a + dx
                adc     dx
                bcs     +           ; if a >= dy then
                cmp     dy          ;
                bcc     ++          ;   a = a - dy
+               sec                 ;   cx++
                sbc     dy
                inc     cx          ; endif
+               inc     cy          ; cy++
                dey
                bne     -
                rts
```

A fenti rutin az 5-ös irány.
- dx = abs(x1 - x0), 
- dy = abs(y1 - y0),
- A cx, cy az aktuális pont a plot rutin hívásakor, a kezdő értéke: x0, y0

Az 5-ös irány esetén a dy nagyobb mint a dx, ezért a ciklusban az y-t fixen lépteti 1-el. Az x-et csak időnként kell léptetni. 
Az x léptetéséhez a rutin az accumulárhoz adogatja hozzá a dx-et, és nézi, hogy elérte-e a dy értékét. Ha átlépte, akkor lépteti az x-et (majd korrigálja az akkumulátort -dy-al). Az akkumulátor kezdő értéke dy / 2.
