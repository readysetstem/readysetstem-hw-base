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
# - WARNING: This makefile runs out of a different repo (readysetstem-hw-base).
#	Ensure that it is syned to the latest.
# - First time for an new EagleCAD schematic/board (after first time, manually
# diff/update files if needed):
#     - cp readysetstem-hw-base/PCB/Makefile <your_proj>/
# - Prepare fab notes
#     - If README.txt does not exist, "make" once to create it.
#     - Add any additional fab notes in README.txt
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
#             - Select readysetstem-hw-base/PCB/sfe-gerb274x.cam
#         - File->Open->Board...
#             - Select <name>.BRD from this directory
#         - Click "Process Job"
#         - All files should now be created in the gerbers directory.
# - Check in all files to git
# - git tag, with name-version.  For example:
#     git tag lid_gamer_pcb-01b
# - Create archive with "make".  Filename will be <name>.zip
# - Save package in Google Drive
#
# ADDING LOGO TO A BRD FILE
#
# How to import logo into eaglecad from inkscape
# - Download svg2poly ULP:
#      https://github.com/cmonr/Eagle-ULPs
# - General instructions are on svg2poly github page
#	- Recommends to "Add Nodes", but not necessary
# - To import into EagleCAD:
#	- In Inkscape:
#		- Open AI logo (ReadySetSTEM_Logo_Black.ai)
#		- Confirm: Preferences > SVG output > Path data, tick
#			"Allow relative coordinates"
#		- Select all and _completely_ ungroup (multiple ctrl-shirt-G)
#		- Delete text paths from logo (if not needed)
#		- With Node cursor tool selected (F2):
#			- Select all (ctrl-a)
#			- Extensions > Modify Path > Flatten Beziers (Flatness: 0.5)
#				- May need to modify decrease flatness for small logos
#			- Select all (ctrl-a)
#			- Break Apart (ctrl-shift-k)
#		- File -> Save As... -> anything.svg (Format: Plain SVG)
#	- In EagleCAD
#		- Open *.brd file of PCB
#		- MARK location to import image
#		- Run ULP... -> svg2poly.ulp
#		- Choose anything.svg created earlier
#		- When importing, there appears to be an extra rectangle polygon.
#			Delete it.
#		- Group/move logo to correct location.
#		- May need to group/rotate logo
#		- May need to group/rotate mirror
#		- Group/change layer to tPlace (if on top) or bPlace (if on bottom)
#		- Group/change width to 1 (IMPORTANT!!!  Needed for correct gerber export)
# - You likely will have to resize in inkscape and repeat the import to
#   get the right size. (400x400px worked for HeaderConnectorBoard)
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

GERBER_EXTENSIONS=GKO GBL GBO GBS GBP GTL GTO GTP GTS GML TXT dri gpi
GERBERS=$(addprefix gerbers/$(NAME).,$(GERBER_EXTENSIONS))

MASTER_README=$(COMMON_DIR)/README.txt
README=README.txt

SOURCES=$(SCH) $(BRD) $(LIB) $(BOM) $(JPG) $(README) $(GERBERS)

# ZIP output file name contains file rev
ZIP=$(NAME)-$(BRD_REV).zip

$(ZIP): $(SOURCES) Makefile
	rm -f $@
	zip $@ $(SOURCES)
	@if ! diff -q $(MASTER_README) $(README) >/dev/null; then \
		echo "##########################################################################"; \
		echo "### "; \
		echo "### NOTE: Fab notes ($(README)) differes from default."; \
		echo "### "; \
		echo "### Differences shown below.  Please verify."; \
		echo "### "; \
		echo "##########################################################################"; \
		colordiff $(MASTER_README) $(README); \
	fi
	
$(README): $(MASTER_README)
	@echo "##########################################################################"
	@echo "### "
	@echo "### WARNING: "
	@echo "### "
	@echo "### README.txt did not exist.  Creating default"
	@echo "### "
	@echo "### Final package will not be built.  Veryify README and rerun make"
	@echo "### "
	@echo "##########################################################################"
	cp $(MASTER_README) $(README)
	exit 1


help:
	@# Print header of this file
	awk '/^#/;/^[^#]/{exit}' $(COMMON_DIR)/master.mak

clean:
	rm -f $(ZIP)
	
