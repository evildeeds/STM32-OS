################################################################################
#
# wireless_tools
#
################################################################################

WIRELESS_TOOLS_VERSION_MAJOR = 30
WIRELESS_TOOLS_VERSION = $(WIRELESS_TOOLS_VERSION_MAJOR).pre9
WIRELESS_TOOLS_SITE = https://hewlettpackard.github.io/wireless-tools
WIRELESS_TOOLS_SOURCE = wireless_tools.$(WIRELESS_TOOLS_VERSION).tar.gz
WIRELESS_TOOLS_LICENSE = GPL-2.0
WIRELESS_TOOLS_LICENSE_FILES = COPYING
WIRELESS_TOOLS_CPE_ID_VERSION = $(WIRELESS_TOOLS_VERSION_MAJOR)
WIRELESS_TOOLS_CPE_ID_UPDATE = pre9
WIRELESS_TOOLS_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_WIRELESS_TOOLS_IWCONFIG),y)
WIRELESS_TOOLS_BUILD_TARGETS = iwmulticall
WIRELESS_TOOLS_INSTALL_TARGETS = install-iwmulticall
endif

ifeq ($(BR2_PACKAGE_WIRELESS_TOOLS_IFRENAME),y)
WIRELESS_TOOLS_BUILD_TARGETS += ifrename
endif

ifeq ($(BR2_PACKAGE_WIRELESS_TOOLS_LIB),y)
WIRELESS_TOOLS_BUILD_TARGETS += libiw.so.$(WIRELESS_TOOLS_VERSION_MAJOR)
WIRELESS_TOOLS_INSTALL_TARGETS += install-dynamic

define WIRELESS_TOOLS_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) PREFIX="$(STAGING_DIR)" LDCONFIG=/bin/true \
		install-dynamic
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) PREFIX="$(STAGING_DIR)/usr" install-hdr
endef

endif

define WIRELESS_TOOLS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" \
		$(WIRELESS_TOOLS_BUILD_TARGETS)
endef

define WIRELESS_TOOLS_INSTALL_TARGET_CMDS
	$(if $(WIRELESS_TOOLS_INSTALL_TARGETS),
		$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) PREFIX="$(TARGET_DIR)" \
			LDCONFIG=/bin/true $(WIRELESS_TOOLS_INSTALL_TARGETS))
	$(if $(BR2_PACKAGE_WIRELESS_TOOLS_IFRENAME),
		$(INSTALL) -D -m 755 $(@D)/ifrename $(TARGET_DIR)/sbin/ifrename)
endef

$(eval $(generic-package))
