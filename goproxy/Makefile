# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2026

include $(TOPDIR)/rules.mk

PKG_NAME:=goproxy
PKG_VERSION:=latest
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0-only
PKG_MAINTAINER:=snail007

include $(INCLUDE_DIR)/package.mk

ifeq ($(ARCH),x86_64)
  GOPROXY_RELEASE_ARCH:=amd64
else ifeq ($(ARCH),i386)
  GOPROXY_RELEASE_ARCH:=386
else ifeq ($(ARCH),aarch64)
  GOPROXY_RELEASE_ARCH:=arm64-v8
else ifeq ($(ARCH),arm)
  ifeq ($(CONFIG_arm_v5),y)
    GOPROXY_RELEASE_ARCH:=arm-v5
  else ifeq ($(CONFIG_arm_v6),y)
    GOPROXY_RELEASE_ARCH:=arm-v6
  else ifeq ($(CONFIG_arm_v8),y)
    GOPROXY_RELEASE_ARCH:=arm-v8
  else
    GOPROXY_RELEASE_ARCH:=arm-v7
  endif
else ifeq ($(ARCH),mips)
  ifeq ($(CONFIG_SOFT_FLOAT),y)
    GOPROXY_RELEASE_ARCH:=mips-softfloat
  else
    GOPROXY_RELEASE_ARCH:=mips
  endif
else ifeq ($(ARCH),mipsel)
  ifeq ($(CONFIG_SOFT_FLOAT),y)
    GOPROXY_RELEASE_ARCH:=mipsle-softfloat
  else
    GOPROXY_RELEASE_ARCH:=mipsle
  endif
else ifeq ($(ARCH),mips64)
  ifeq ($(CONFIG_SOFT_FLOAT),y)
    GOPROXY_RELEASE_ARCH:=mips64-softfloat
  else
    GOPROXY_RELEASE_ARCH:=mips64
  endif
else ifeq ($(ARCH),mips64el)
  ifeq ($(CONFIG_SOFT_FLOAT),y)
    GOPROXY_RELEASE_ARCH:=mips64le-softfloat
  else
    GOPROXY_RELEASE_ARCH:=mips64le
  endif
endif

GOPROXY_SOURCE:=proxy-linux-$(GOPROXY_RELEASE_ARCH).tar.gz

define Package/goproxy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Goproxy prebuilt binary
  URL:=https://github.com/snail007/goproxy
  DEPENDS:=@(aarch64||arm||i386||mips||mips64||mips64el||mipsel||x86_64)
endef

define Package/goproxy/description
 Goproxy is a multi-protocol proxy tool. This package downloads the latest
 free upstream release binary for the current OpenWrt target architecture.
endef

define Package/goproxy/conffiles
/etc/proxy/blocked
/etc/proxy/direct
/etc/proxy/hosts
/etc/proxy/resolve.rules
/etc/proxy/rewriter.rules
/etc/proxy/rhttp.toml
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	@if [ -z "$(GOPROXY_RELEASE_ARCH)" ]; then \
		echo "Unsupported goproxy architecture: $(ARCH)"; \
		exit 1; \
	fi
	@case "$(GOPROXY_SOURCE)" in *_commercial*) \
		echo "Refusing to download commercial goproxy release asset: $(GOPROXY_SOURCE)"; \
		exit 1; \
	esac
	@echo "Downloading https://github.com/snail007/goproxy/releases/latest/download/$(GOPROXY_SOURCE)"
	wget -O "$(PKG_BUILD_DIR)/$(GOPROXY_SOURCE)" "https://github.com/snail007/goproxy/releases/latest/download/$(GOPROXY_SOURCE)"
	tar -xzf "$(PKG_BUILD_DIR)/$(GOPROXY_SOURCE)" -C "$(PKG_BUILD_DIR)"
	test -f "$(PKG_BUILD_DIR)/proxy"
endef

define Build/Compile
endef

define Package/goproxy/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/proxy $(1)/usr/bin/proxy
	$(INSTALL_DIR) $(1)/etc/proxy
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/blocked $(1)/etc/proxy/blocked
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/direct $(1)/etc/proxy/direct
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/hosts $(1)/etc/proxy/hosts
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/resolve.rules $(1)/etc/proxy/resolve.rules
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/rewriter.rules $(1)/etc/proxy/rewriter.rules
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/rhttp.toml $(1)/etc/proxy/rhttp.toml
endef

$(eval $(call BuildPackage,goproxy))
