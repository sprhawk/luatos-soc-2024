#ifndef __PKG_718U_MAPCHK_H__
#define __PKG_718U_MAPCHK_H__

//compare sdk used address or size with the package image memory lna
//each time the flash layout changed, both sdk used address/size and the package image memory lna/size should be updated 

#if ((AP_FLASH_LOAD_ADDR)!=(AP_PKGIMG_LNA))
#error "718U (AP_FLASH_LOAD_ADDR)!=(AP_PKGIMG_LNA)"
#endif

#if ((BOOTLOADER_FLASH_LOAD_ADDR)!=(BL_PKGIMG_LNA))
#error "718U (BOOTLOADER_FLASH_LOAD_ADDR)!=(BL_PKGIMG_LNA)"
#endif

//For 718U, CP image in AP Flash
#if ((CP_FLASH_LOAD_ADDR-AP_FLASH_XIP_ADDR)!=(CP_PKGIMG_LNA-AP_FLASH_BASE_LNA))
#error "718U ((CP_FLASH_LOAD_ADDR-AP_FLASH_XIP_ADDR)!=(CP_PKGIMG_LNA-AP_FLASH_BASE_LNA))"
#endif



#if ((BOOTLOADER_FLASH_LOAD_SIZE)!=(BOOTLOADER_PKGIMG_LIMIT_SIZE))
#error "718U (BOOTLOADER_FLASH_LOAD_SIZE)!=(BOOTLOADER_PKGIMG_LIMIT_SIZE)"
#endif

#if ((AP_FLASH_LOAD_SIZE)!=(AP_PKGIMG_LIMIT_SIZE))
#error "718U (AP_FLASH_LOAD_SIZE)!=(AP_PKGIMG_LIMIT_SIZE)"
#endif

#if ((CP_FLASH_LOAD_SIZE)!=(CP_PKGIMG_LIMIT_SIZE))
#error "718U (CP_FLASH_LOAD_SIZE)!=(CP_PKGIMG_LIMIT_SIZE)"
#endif


#endif

