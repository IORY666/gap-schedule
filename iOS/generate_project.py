"""生成兼容 Xcode 15 的 project.pbxproj"""
import uuid, os, sys

def uid():
    return uuid.uuid4().hex[:24].upper()

SWIFT_FILES = [
    "GapSchedule/GapScheduleApp.swift",
    "GapSchedule/ContentView.swift",
    "GapSchedule/Models/TaskData.swift",
    "GapSchedule/Views/CalendarGridView.swift",
    "GapSchedule/Views/TaskRowView.swift",
    "GapSchedule/Views/ReminderPopupView.swift",
    "GapSchedule/Managers/NotificationManager.swift",
    "GapSchedule/Managers/ScheduleManager.swift",
    "GapSchedule/Managers/SpeechManager.swift",
]

# Generate UUIDs
P = uid()  # Project
MG = uid() # Main group
SG = uid() # GapSchedule group
MG2 = uid() # Models group
VG = uid() # Views group
MGG = uid() # Managers group
NT = uid() # Native target
BP = uid() # Build phase - sources
BR = uid() # Build phase - resources
PR = uid() # Product reference
CL1 = uid() # Config list - project
CL2 = uid() # Config list - target
CB1 = uid() # Config - project debug
CB2 = uid() # Config - project release
CB3 = uid() # Config - target debug
CB4 = uid() # Config - target release

file_refs = {}
build_files = {}

for f in SWIFT_FILES:
    fr = uid(); bf = uid()
    file_refs[f] = fr; build_files[f] = bf

# Info.plist
info_fr = uid(); info_bf = uid()

# Products group
PROD = uid()

content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
"""

# Build files
for f in SWIFT_FILES:
    content += f"\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {os.path.basename(f)} */; }};\n"

content += f"""\t\t{info_bf} /* Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {info_fr} /* Info.plist */; }};\n"""

content += """
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
"""

for f in SWIFT_FILES:
    content += f"\t\t{file_refs[f]} /* {os.path.basename(f)} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {os.path.basename(f)}; sourceTree = \"<group>\"; }};\n"

content += f"""\t\t{info_fr} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};\n"""
content += f"""\t\t{PR} /* GapSchedule.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = GapSchedule.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n"""

content += """
/* End PBXFileReference section */

/* Begin PBXGroup section */
"""

content += f"""\t\t{MG} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{SG} /* GapSchedule */,
\t\t\t\t{PROD} /* Products */,
\t\t\t);
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{SG} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_refs[SWIFT_FILES[0]]} /* GapScheduleApp.swift */,
\t\t\t\t{file_refs[SWIFT_FILES[1]]} /* ContentView.swift */,
\t\t\t\t{MG2} /* Models */,
\t\t\t\t{VG} /* Views */,
\t\t\t\t{MGG} /* Managers */,
\t\t\t\t{info_fr} /* Info.plist */,
\t\t\t);
\t\t\tpath = GapSchedule;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{MG2} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_refs[SWIFT_FILES[2]]} /* TaskData.swift */,
\t\t\t);
\t\t\tpath = Models;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{VG} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_refs[SWIFT_FILES[3]]} /* CalendarGridView.swift */,
\t\t\t\t{file_refs[SWIFT_FILES[4]]} /* TaskRowView.swift */,
\t\t\t\t{file_refs[SWIFT_FILES[5]]} /* ReminderPopupView.swift */,
\t\t\t);
\t\t\tpath = Views;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{MGG} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_refs[SWIFT_FILES[6]]} /* NotificationManager.swift */,
\t\t\t\t{file_refs[SWIFT_FILES[7]]} /* ScheduleManager.swift */,
\t\t\t\t{file_refs[SWIFT_FILES[8]]} /* SpeechManager.swift */,
\t\t\t);
\t\t\tpath = Managers;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{PROD} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{PR} /* GapSchedule.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = \"<group>\";
\t\t}};
"""

content += """
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
"""

content += f"""\t\t{NT} /* GapSchedule */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {CL2} /* Build configuration list */;
\t\t\tbuildPhases = (
\t\t\t\t{BP} /* Sources */,
\t\t\t\t{BR} /* Resources */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = GapSchedule;
\t\t\tproductName = GapSchedule;
\t\t\tproductReference = {PR} /* GapSchedule.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
"""

content += """
/* End PBXNativeTarget section */

/* Begin PBXProject section */
"""

content += f"""\t\t{P} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1540;
\t\t\t\tLastUpgradeCheck = 1540;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{NT} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.4;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {CL1} /* Build configuration list */;
\t\t\tcompatibilityVersion = "Xcode 15.0";
\t\t\tdevelopmentRegion = "zh-Hans";
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, "zh-Hans");
\t\t\tmainGroup = {MG};
\t\t\tproductRefGroup = {PROD} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{NT} /* GapSchedule */,
\t\t\t);
\t\t}};
"""

content += """
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
"""

content += f"""\t\t{BR} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{info_bf} /* Info.plist in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
"""

content += """
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
"""

content += f"""\t\t{BP} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
"""
for f in SWIFT_FILES:
    content += f"\t\t\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */,\n"
content += """\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
"""

content += """
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
"""

for cfg_id, cfg_name, cfg_product, cfg_target in [
    (CB1, "Debug", P, None), (CB2, "Release", P, None),
    (CB3, "Debug", None, NT), (CB4, "Release", None, NT)
]:
    if cfg_target:
        content += f"""\t\t{cfg_id} /* {cfg_name} */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = NO;
\t\t\t\tINFOPLIST_FILE = GapSchedule/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.gap.schedule;
\t\t\t\tPRODUCT_NAME = GapSchedule;
\t\t\t\tSUPPORTED_PLATFORMS = iphoneos;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = {cfg_name};
\t\t}};
"""
    else:
        content += f"""\t\t{cfg_id} /* {cfg_name} */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = {cfg_name};
\t\t}};
"""

content += """
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
"""

content += f"""\t\t{CL1} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({CB1}, {CB2});
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{CL2} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({CB3}, {CB4});
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
"""

content += """
/* End XCConfigurationList section */
\t};
\trootObject = """ + f"{P} /* Project object */;" + """
}
"""

out_dir = "GapSchedule.xcodeproj"
os.makedirs(out_dir, exist_ok=True)
with open(os.path.join(out_dir, "project.pbxproj"), "w", encoding="utf-8") as f:
    f.write(content)
print(f"Generated {out_dir}/project.pbxproj ({len(content)} bytes)")

# Also generate xcscheme
scheme_dir = os.path.join(out_dir, "xcshareddata", "xcschemes")
os.makedirs(scheme_dir, exist_ok=True)
scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1540" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference
               BuildableIdentifier="primary"
               BlueprintIdentifier="{NT}"
               BuildableName="GapSchedule.app"
               BlueprintName="GapSchedule"
               ReferencedContainer="container:GapSchedule.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables></Testables></TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{NT}" BuildableName="GapSchedule.app" BlueprintName="GapSchedule" ReferencedContainer="container:GapSchedule.xcodeproj"></BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{NT}" BuildableName="GapSchedule.app" BlueprintName="GapSchedule" ReferencedContainer="container:GapSchedule.xcodeproj"></BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"></ArchiveAction>
</Scheme>"""
with open(os.path.join(scheme_dir, "GapSchedule.xcscheme"), "w", encoding="utf-8") as f:
    f.write(scheme)
print(f"Generated xcscheme with target UUID: {NT}")
print(f"objectVersion: 56 (Xcode 15 compatible)")
print(f"Sources: {len(SWIFT_FILES)} files")
