MEMORY
{
   BRAM (RWX) : ORIGIN = 0x0000, LENGTH = 0x400  /* 1024B RAM */
}
SECTIONS
{
    everything :
    {
	. = ALIGN(4);
        *(.*)
    } >BRAM
}