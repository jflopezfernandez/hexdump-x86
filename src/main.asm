
;==============================================================================
;
;  Executable name : hexdump-x86
;  Version         : 1.0
;  Created date    : 6/6/2019
;  Last update     : 6/6/2019
;  Author          : Jose Fernando Lopez Fernandez
;  Description     : Print hexdump of input
;
;
;  Build using these commands:
;
;       nasm -f elf -g -F stabs main.asm
;       ld -m elf_i386 -o hexdump-x86 main.o
;
;  Run as:
;
;       hexdump-x86 < file
;
;==============================================================================
;
;                          PREPROCESSOR DEFINITIONS
;
;------------------------------------------------------------------------------

    %define     EOF             0

    %define     STDIN           0
    %define     STDOUT          1
    %define     STDERR          2

    %define     SYSCALL_EXIT    1
    %define     SYSCALL_READ    3
    %define     SYSCALL_WRITE   4

    %define     SECTOR_SIZE     512
    %define     BUFFER_SIZE     16

;==============================================================================
;
;                            DATA SEGMENT
;
;==============================================================================

                SECTION .data

DIGITS:         db "0123456789ABCDEF"

HEXSTR:         db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",10
HEXLEN:         equ $-HEXSTR

;==============================================================================
;
;                             BSS SEGMENT
;
;==============================================================================

                SECTION .bss

BUFF            RESB    BUFFER_SIZE         ; Input buffer for reading input

;==============================================================================
;
;
;
;==============================================================================

                SECTION .text			    ; Section containing code

                GLOBAL 	_start			    ; Global entry point
                GLOBAL  EXIT

;==============================================================================
;
;                               EXIT
;
;==============================================================================
;
;       This is the exit point of the application. The function passes
;       on its argument in RBX as the exit code unmodifed. For this
;       reason, the onus is on the calling functions to specify an 
;       actual return code in RBX, as calling the EXIT function without
;       ensuring a value is being purposely set will result in a non-
;       zero return code nearly all of the time, statistically speaking.
;
;       This is signficant because a non-zero exit code signifies a run-
;       time error in the application, and therefore a false alarm in 
;       this specific case.
;
;------------------------------------------------------------------------------

EXIT:           MOV     EAX,SYSCALL_EXIT
                INT     0x80                ; Return exit code in RBX

;==============================================================================
;
;                           PROGRAM START
;
;==============================================================================

_start:         ; Enter the read, convert, print loop

.READ:          MOV     EAX,SYSCALL_READ    ; Set system call read
                MOV     EBX,STDIN           ; File descriptor STDIN
                MOV     ECX,BUFF            ; Buffer address
                MOV     EDX,BUFFER_SIZE     ; Reading 16 bytes at a time
                INT     0x80                ; Call kernel
                MOV     EBP,EAX             ; Save number of bytes read
                CMP     EAX,EOF             ; Check for EOF
                JE      .DONE               ; If EOF, goto EXIT
                
                ; Initialize registers to process the buffer

                MOV     ESI,BUFF            ; Source -> Buffer
                MOV     EDI,HEXSTR          ; Destination -> Hex String
                XOR     ECX,ECX             ; Initialize counter register

                ; Iterate through buffer, converting from binary to hex

.SCAN:          XOR     EAX,EAX             ; Reset EAX

                ; Calculate the offset into HEXSTR: EDX = ECX * 3

                MOV     EDX,ECX             ; EDX = ECX
                SHL     EDX,1               ; EDX = ECX * 2
                ADD     EDX,ECX             ; EDX = ECX * 2 + ECX = ECX * 3

                ; Get a char from buffer and put into EAX and EBX

                MOV     AL,BYTE[ESI+ECX]    ; Put byte from buf into AL
                MOV     EBX,EAX             ; Duplicate for second nybble

                ; Look up low nybble character and insert into string.

                AND     AL,0x0F             ; Mask out all but low nybble
                MOV     AL,BYTE[DIGITS+EAX] ; Look up char equiv of nybble
                MOV     BYTE[HEXSTR+EDX+2],AL

                ; Look up high nybble character and insert into string.

                SHR     BL,4                ; Shift high 4 bits into low 4 bits
                MOV     BL,BYTE[DIGITS+EBX] ; Look up char equiv of nybble
                MOV     BYTE[HEXSTR+EDX+1],BL

                ; Bump the buffer pointer to the next character and check done

                INC     ECX                 ; Increment line string pointer
                CMP     ECX,EBP             ; Compare to number of chars in buf
                JNA     .SCAN               ; if (ECX <= BUFFER_SIZE) loop back

                ; Write the line of hex values to stdout.

                MOV     EAX,SYSCALL_WRITE   ; Set syscall write
                MOV     EBX,STDOUT          ; File descriptor stdout
                MOV     ECX,HEXSTR          ; Hex vals string address
                MOV     EDX,HEXLEN          ; String length
                INT     0x80                ; Call kernel
                JMP     .READ               ; Clear input buffer

.DONE:          PUSH    10                  ; Move newline char to ESP
                MOV     EAX,SYSCALL_WRITE   ; Set syscall write
                MOV     EBX,STDOUT          ; File descriptor STDOUT
                MOV     ECX,ESP             ; Newline char in stack
                MOV     EDX,1               ; Printing single char
                INT     0x80                ; Call kernel
                POP     EAX                 ; Reset stack
                XOR     EBX,EBX             ; Set exit code 0
                CALL    EXIT                ; Call exit

