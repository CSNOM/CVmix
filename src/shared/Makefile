.SUFFIXES: .F90 .o
extension = .F90

# Need CVMix root directory
# If using old version of make, pass in CVMIX_ROOT
ifeq ($(wildcard $(MAKEFILE_LIST)),)
  CVMIX_ROOT = ../..
else
  ThisMakefile=$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
  ifeq (/,$(findstring /,$(ThisMakefile)))
    ThisDir=$(shell x=$(ThisMakefile) && echo $${x%/*})/
  endif
  CVMIX_ROOT = $(realpath $(ThisDir)../..)
endif

SETUP_FILE = $(CVMIX_ROOT)/bld/cvmix_setup
ENV_FILE = $(CVMIX_ROOT)/bld/.CVMix_env
# Directories used in Makefile
# Check to this is standalone CVMix or not (look for $CVMIX_ROOT/.CVMix_env)
ifneq ($(wildcard $(SETUP_FILE)),)
  SRC_DIR = $(CVMIX_ROOT)/src/shared
  BLD_DIR = $(CVMIX_ROOT)/bld
  OBJ_DIR = $(BLD_DIR)/obj
  LIB_DIR = $(CVMIX_ROOT)/lib
  INC_DIR = $(CVMIX_ROOT)/include
  ifeq ($(wildcard $(ENV_FILE)),)
    NEED_ENV_FILE = TRUE
  else
    # Read in Compiler information
    include $(BLD_DIR)/.CVMix_env
    NEED_ENV_FILE = FALSE
  endif
  # Read in FCFLAGS
  include $(BLD_DIR)/CompileFlags.mak
else
  SRC_DIR = .
  OBJ_DIR = .
  LIB_DIR = .
  INC_DIR = .
  FC = NONE
  NEED_ENV_FILE = FALSE
endif

ifeq ($(FC),NONE)
  NOFC = TRUE
endif

MODULES = cvmix_background.F90 \
          cvmix_convection.F90 \
          cvmix_ddiff.F90 \
          cvmix_put_get.F90 \
          cvmix_shear.F90 \
          cvmix_tidal.F90

ifneq ($(OBJ_DIR),$(INC_DIR))
  INCS = $(INC_DIR)/cvmix_kinds_and_types.mod \
         $(addprefix $(INC_DIR)/,${MODULES:.F90=.mod})
endif
MODS = $(OBJ_DIR)/cvmix_kinds_and_types.mod \
       $(addprefix $(OBJ_DIR)/,${MODULES:.F90=.mod}) \
       $(INCS)
OBJS = $(addprefix $(OBJ_DIR)/,${MODULES:.F90=.o})
KINDS_OBJ = $(OBJ_DIR)/cvmix_kinds_and_types.o

### TARGETS ###

.PHONY: clean recurse check

all: recurse

recurse: check
ifeq ($(NEED_ENV_FILE),FALSE)
	$(MAKE) $(LIB_DIR)/libcvmix.a $(INCS)
endif

# Create all object and module files
# Note that .mod files need to be copied to INC_DIR

### cvmix_kinds_and_types.F90
$(OBJ_DIR)/cvmix_kinds_and_types.o: $(SRC_DIR)/cvmix_kinds_and_types.F90
	$(FC) $(FCFLAGS) -c $(SRC_DIR)/cvmix_kinds_and_types.F90 -o $@

$(INC_DIR)/cvmix_kinds_and_types.mod: $(SRC_DIR)/cvmix_kinds_and_types.F90 \
                          $(OBJ_DIR)/cvmix_kinds_and_types.o
	cp $(OBJ_DIR)/cvmix_kinds_and_types.mod $@

### cvmix_put_get.F90
$(OBJ_DIR)/cvmix_put_get.o: $(SRC_DIR)/cvmix_put_get.F90       \
                            $(OBJ_DIR)/cvmix_kinds_and_types.o
	$(FC) $(FCFLAGS) -c $(SRC_DIR)/cvmix_put_get.F90 -o $@

$(INC_DIR)/cvmix_put_get.mod: $(SRC_DIR)/cvmix_put_get.F90       \
                              $(OBJ_DIR)/cvmix_put_get.o
	cp $(OBJ_DIR)/cvmix_put_get.mod $@

### cvmix_background.F90
$(OBJ_DIR)/cvmix_background.o: $(SRC_DIR)/cvmix_background.F90    \
                               $(OBJ_DIR)/cvmix_put_get.o         \
                               $(OBJ_DIR)/cvmix_kinds_and_types.o
	$(FC) $(FCFLAGS) -c $(SRC_DIR)/cvmix_background.F90 -o $@

$(INC_DIR)/cvmix_background.mod: $(SRC_DIR)/cvmix_background.F90       \
                              $(OBJ_DIR)/cvmix_background.o
	cp $(OBJ_DIR)/cvmix_background.mod $@

### cvmix_convection.F90
$(OBJ_DIR)/cvmix_convection.o: $(SRC_DIR)/cvmix_convection.F90    \
                               $(OBJ_DIR)/cvmix_kinds_and_types.o
	$(FC) $(FCFLAGS) -c $(SRC_DIR)/cvmix_convection.F90 -o $@

$(INC_DIR)/cvmix_convection.mod: $(SRC_DIR)/cvmix_convection.F90       \
                              $(OBJ_DIR)/cvmix_convection.o
	cp $(OBJ_DIR)/cvmix_convection.mod $@

### cvmix_shear.F90
$(OBJ_DIR)/cvmix_shear.o: $(SRC_DIR)/cvmix_shear.F90         \
                          $(OBJ_DIR)/cvmix_kinds_and_types.o
	$(FC) $(FCFLAGS) -c $(SRC_DIR)/cvmix_shear.F90 -o $@

$(INC_DIR)/cvmix_shear.mod: $(SRC_DIR)/cvmix_shear.F90       \
                              $(OBJ_DIR)/cvmix_shear.o
	cp $(OBJ_DIR)/cvmix_shear.mod $@

### cvmix_tidal.F90
$(OBJ_DIR)/cvmix_tidal.o: $(SRC_DIR)/cvmix_tidal.F90         \
                          $(OBJ_DIR)/cvmix_kinds_and_types.o
	$(FC) $(FCFLAGS) -c $(SRC_DIR)/cvmix_tidal.F90 -o $@

$(INC_DIR)/cvmix_tidal.mod: $(SRC_DIR)/cvmix_tidal.F90       \
                              $(OBJ_DIR)/cvmix_tidal.o
	cp $(OBJ_DIR)/cvmix_tidal.mod $@

### cvmix_ddiff.F90
$(OBJ_DIR)/cvmix_ddiff.o: $(SRC_DIR)/cvmix_ddiff.F90         \
                          $(OBJ_DIR)/cvmix_kinds_and_types.o
	$(FC) $(FCFLAGS) -c $(SRC_DIR)/cvmix_ddiff.F90 -o $@

$(INC_DIR)/cvmix_ddiff.mod: $(SRC_DIR)/cvmix_ddiff.F90       \
                              $(OBJ_DIR)/cvmix_ddiff.o
	cp $(OBJ_DIR)/cvmix_ddiff.mod $@

### Combine into library
$(LIB_DIR)/libcvmix.a: $(KINDS_OBJ) $(OBJS)
	ar -ru $(LIB_DIR)/libcvmix.a $(OBJS)

# Utilities:
# 1) check ensures that FC has been specified
# 2) clean deletes object and mod files
check:
	@$(if $(NOFC), echo "ERROR: you must specify FC (and it is recommended that \
     you specify FCFLAGS"; echo "as well)."; exit 1)
ifeq ($(NEED_ENV_FILE),TRUE)
	../../bld/cvmix_setup ../../bld/.CVMix_env; $(MAKE)
endif

clean:
	/bin/rm -f $(LIB_DIR)/libcvmix.a $(OBJS) $(KINDS_OBJ) $(MODS) $(KINDS_MOD)
