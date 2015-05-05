#
# HOW TO GENERATE A PCB PACKAGE FROM EAGLECAD
#
# A package is a zipfile consisting of:
#     - EagleCAD schematic/board files
#     - Excel format BOM
#     - gerbers generated from Eagle
#     - README.txt with fab notes
#     - Images with details
#
# TO CREATE THE PACKAGE
#
# - First time for an new EagleCAD schematic/board:
#     - cp raspberrystem-hw-base/PCB/Makefile <your_proj>/
# - Prepare fab notes
#     - Add any additional fab notes in README-BRD.txt
#     - Add any images for reference.  In general, this is likely prototype
#       images of (with annotation, as needed):
#         - board-top.jpg
#         - board-bottom.jpg
# - Create/Verify BOM
# - In Eagle:
#     - Verify schematic/board files are complete
#     - Update version on silkscreen if needed.
#     - Run ERC/DRC check in Eagle
#     - NOTE: a directory "gerbers" must exist
#     - Then,
#         - File->CAM Processor...
#         - File->Open->Job...
#             - Select raspberrystem-hw-base/PCB/sfe-gerb274x.cam
#         - File->Open->Board...
#             - Select <name>.BRD from this directory
#         - Click "Process Job"
#         - All files should now be created in the gerbers directory.
# - Check in all files to git
# - git tag, with name-version.  For example:
#		git tag lid_gamer_pcb-01b
# - Create archive with "make".  Filename will be <name>.zip
# - Save package in Dropbox
#
SCH=$(wildcard *.sch)

ifneq ($(words $(SCH)),1)
  $(error Must have EXACTLY 1 *.sch file in this directory)
endif

NAME=$(basename $(SCH))
BOM=$(NAME)_BOM.xls

# We include all JPGs, whether in git or not.  So we better not have left
# crufty images around.
JPG=$(wildcard *.jpg)

# Get board rev from BRD file.
BRD=$(NAME).brd
BRD_REV=$(shell grep -o Rev-[0-9][0-9][a-z] $(BRD))
ifeq ($(BRD_REV),)
  BRD_REV=XXX
endif

# Eagle Library - its okay if it doesn't exist
LIB=$(NAME).lbr
ifneq ($(wildcard $(LIB)),$(LIB))
  LIB=
endif

GERBER_EXTENSIONS=GBL GBO GBS GTL GTO GTP GTS TXT dri gpi
GERBERS=$(addprefix gerbers/$(NAME).,$(GERBER_EXTENSIONS))

MASTER_README=$(COMMON_DIR)/README.txt
README=README.txt
README_BRD=$(wildcard README-BRD.txt)

SOURCES=$(SCH) $(BRD) $(LIB) $(BOM) $(JPG) $(README) $(README_BRD) $(GERBERS)

# ZIP output file name contains file rev
ZIP=$(NAME)-$(BRD_REV).zip

$(ZIP): $(SOURCES) Makefile
	rm -f $@
	zip $@ $(SOURCES)

.INTERMEDIATE: $(README)
$(README): $(MASTER_README)
	cp $(MASTER_README) $(README)

help:
	@# Print header of this file
	awk '/^#/;/^[^#]/{exit}' $(COMMON_DIR)/master.mak

clean:
	rm -f $(ZIP)
	
