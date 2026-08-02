"""在 pbxproj 中注入 Widget Extension target"""
import re, uuid, os

def uid24():
    return uuid.uuid4().hex[:24].upper()

path = "GapSchedule.xcodeproj/project.pbxproj"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Widget target 的 UUID 池
WNT = uid24()  # Widget PBXNativeTarget
WBP = uid24()  # Widget Sources build phase
WBR = uid24()  # Widget Resources build phase
WCL = uid24()  # Widget Config list
WCB1 = uid24() # Widget Debug config
WCB2 = uid24() # Widget Release config
WPR = uid24()  # Widget product ref (.appex)
WFR_SWIFT = uid24()  # Widget.swift file ref
WBF_SWIFT = uid24()  # Widget.swift build file
WFR_PLIST = uid24()  # Widget Info.plist file ref
WBF_PLIST = uid24()  # Widget Info.plist build file
WGROUP = uid24()     # Widget group
ECP = uid24()  # Embed App Extensions copy files phase
TPX = uid24()  # Target dependency proxy
TDP = uid24()  # Target dependency
EWBF = uid24() # Embed Widget build file

# 2. 在 PBXBuildFile section 末尾插入 Widget build files
build_marker = "/* End PBXBuildFile section */"
widget_build_files = f"""\t\t{WBF_SWIFT} /* GAPWidget.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {WFR_SWIFT} /* GAPWidget.swift */; }};
\t\t{WBF_PLIST} /* Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {WFR_PLIST} /* Info.plist */; }};
\t\t{EWBF} /* GapScheduleWidget.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {WPR} /* GapScheduleWidget.appex */; }};"""
content = content.replace(build_marker, widget_build_files + "\n" + build_marker)

# 3. 在 PBXFileReference section 末尾插入 Widget file refs
file_marker = "/* End PBXFileReference section */"
widget_file_refs = f"""\t\t{WFR_SWIFT} /* GAPWidget.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = GAPWidget.swift; sourceTree = "<group>"; }};
\t\t{WFR_PLIST} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
\t\t{WPR} /* GapScheduleWidget.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = GapScheduleWidget.appex; sourceTree = BUILT_PRODUCTS_DIR; }};"""
content = content.replace(file_marker, widget_file_refs + "\n" + file_marker)

# 4. 在 PBXGroup section 添加 Widget group（在 Products group 之前）
group_marker = "/* End PBXGroup section */"
widget_group = f"""\t\t{WGROUP} /* GapScheduleWidget */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{WFR_SWIFT} /* GAPWidget.swift */,
\t\t\t\t{WFR_PLIST} /* Info.plist */,
\t\t\t);
\t\t\tpath = GapScheduleWidget;
\t\t\tsourceTree = "<group>";
\t\t}};"""
content = content.replace(group_marker, widget_group + "\n" + group_marker)

# 5. 把 Widget group 加入 GapSchedule group (SG)
# 找到 GapSchedule group 的 children，在其中插入 Widget group
# GapSchedule group 特征: path = GapSchedule;
match = re.search(r'(/\* GapSchedule \*/ = \{[^}]+children = \(\n)(.*?)(\t\t\t\);[^}]+path = GapSchedule;)', content, re.DOTALL)
if match:
    prefix, children, suffix = match.groups()
    new_children = children.rstrip() + f"\t\t\t\t{WGROUP} /* GapScheduleWidget */,\n"
    new_block = prefix + new_children + suffix
    content = content.replace(match.group(0), new_block)

# 6. 在 PBXNativeTarget section 末尾插入 Widget target
nt_marker = "/* End PBXNativeTarget section */"
widget_target = f"""\t\t{WNT} /* GapScheduleWidget */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {WCL};
\t\t\tbuildPhases = (
\t\t\t\t{WBP} /* Sources */,
\t\t\t\t{WBR} /* Resources */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = GapScheduleWidget;
\t\t\tproductName = GapScheduleWidget;
\t\t\tproductReference = {WPR};
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t}};"""
content = content.replace(nt_marker, widget_target + "\n" + nt_marker)

# 7. 在 App target 中添加 Embed App Extensions phase
# 从 pbxproj 中提取 App target 的 Resources build phase UUID
res_uuid_match = re.search(r'([A-F0-9]{24}) /\* Resources \*/ = \{', content)
if not res_uuid_match:
    print("ERROR: cannot find Resources build phase UUID")
    exit(1)
app_res_uuid = res_uuid_match.group(1)

app_embed_phase = f"""\t\t\t\t{ECP} /* Embed App Extensions */,"""
# 在 App target 的 buildPhases 中添加嵌入扩展
content = content.replace(
    f"{app_res_uuid} /* Resources */,",
    f"{app_res_uuid} /* Resources */,\n{app_embed_phase}"
)

# 8. 在 PBXProject section 中更新 targets 列表
# 找到 App target UUID 并在其后添加 Widget target
app_target_match = re.search(r'([A-F0-9]{24}) /\* GapSchedule \*/ = \{isa = PBXNativeTarget', content)
if app_target_match:
    app_nt_uuid = app_target_match.group(1)
    content = content.replace(
        f"{app_nt_uuid} /* GapSchedule */,",
        f"{app_nt_uuid} /* GapSchedule */,\n\t\t\t\t{WNT} /* GapScheduleWidget */,"
    )

# 9. 添加 PBXCopyFilesBuildPhase (Embed App Extensions)
copy_files_phase = f"""\t\t{ECP} /* Embed App Extensions */ = {{
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = (
\t\t\t\t{EWBF} /* GapScheduleWidget.appex in Embed App Extensions */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
"""
# 在 PBXResourcesBuildPhase 之前插入
res_marker = "/* Begin PBXResourcesBuildPhase section */"
content = content.replace(res_marker, f"/* Begin PBXCopyFilesBuildPhase section */\n{copy_files_phase}\n/* End PBXCopyFilesBuildPhase section */\n\n{res_marker}")

# 10. 添加 Widget 的 build phases
sources_end = "/* End PBXSourcesBuildPhase section */"
widget_sources = f"""\t\t{WBP} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{WBF_SWIFT} /* GAPWidget.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""
content = content.replace(sources_end, widget_sources + "\n" + sources_end)

res_end = "/* End PBXResourcesBuildPhase section */"
widget_res = f"""\t\t{WBR} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{WBF_PLIST} /* Info.plist in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""
content = content.replace(res_end, widget_res + "\n" + res_end)

# 11. 添加 Widget target 的 build configurations
config_end = "/* End XCBuildConfiguration section */"
widget_configs = f"""\t\t{WCB1} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tINFOPLIST_FILE = GapScheduleWidget/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.gap.schedule.widget;
\t\t\t\tPRODUCT_NAME = GapScheduleWidget;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSUPPORTED_PLATFORMS = iphoneos;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{WCB2} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tINFOPLIST_FILE = GapScheduleWidget/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.gap.schedule.widget;
\t\t\t\tPRODUCT_NAME = GapScheduleWidget;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSUPPORTED_PLATFORMS = iphoneos;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Release;
\t\t}};"""
content = content.replace(config_end, widget_configs + "\n" + config_end)

# 12. 添加 Widget target 的 config list
clist_end = "/* End XCConfigurationList section */"
widget_clist = f"""\t\t{WCL} /* Build configuration list for GapScheduleWidget */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({WCB1} /* Debug */, {WCB2} /* Release */);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};"""
content = content.replace(clist_end, widget_clist + "\n" + clist_end)

# 13. 提取 Project UUID (rootObject)
proj_uuid = re.search(r'rootObject = ([A-F0-9]+)', content)
p_uuid = proj_uuid.group(1) if proj_uuid else "PROJECT_UUID_NOT_FOUND"

# 14. 添加 Target Dependency (App → Widget)
proxy_marker = "/* End PBXNativeTarget section */"
proxy_section = f"""/* Begin PBXContainerItemProxy section */
\t\t{TPX} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {p_uuid} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {WNT};
\t\t\tremoteInfo = GapScheduleWidget;
\t\t}};
/* End PBXContainerItemProxy section */

/* Begin PBXTargetDependency section */
\t\t{TDP} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {WNT} /* GapScheduleWidget */;
\t\t\ttargetProxy = {TPX} /* PBXContainerItemProxy */;
\t\t}};
/* End PBXTargetDependency section */
"""
content = content.replace(proxy_marker, proxy_marker + "\n\n" + proxy_section)

# 15. 在 App target 的 dependencies 中添加 Widget 依赖
app_nt_uuid2 = re.search(r'([A-F0-9]{24}) /\* GapSchedule \*/ = \{isa = PBXNativeTarget;', content)
if app_nt_uuid2:
    nt_id = app_nt_uuid2.group(1)
    content = content.replace(
        f"{nt_id} /* GapSchedule */ = {{\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList",
        f"{nt_id} /* GapSchedule */ = {{\n\t\t\tisa = PBXNativeTarget;\n\t\t\tdependencies = (\n\t\t\t\t{TDP} /* PBXTargetDependency */,\n\t\t\t);\n\t\t\tbuildConfigurationList"
    )

# 16. 修补 xcscheme——在 BuildAction 中加入 Widget target
scheme_path = "GapSchedule.xcodeproj/xcshareddata/xcschemes/GapSchedule.xcscheme"
if os.path.exists(scheme_path):
    with open(scheme_path, "r", encoding="utf-8") as f:
        scheme = f.read()

    # 在 BuildAction 的 BuildActionEntries 中添加 Widget target 的 entry
    widget_entry = f"""\t\t<BuildActionEntry buildForTesting=\"YES\" buildForRunning=\"YES\" buildForProfiling=\"YES\" buildForArchiving=\"YES\" buildForAnalyzing=\"YES\">
\t\t\t<BuildableReference
\t\t\t\tBuildableIdentifier=\"primary\"
\t\t\t\tBlueprintIdentifier=\"{WNT}\"
\t\t\t\tBuildableName=\"GapScheduleWidget.appex\"
\t\t\t\tBlueprintName=\"GapScheduleWidget\"
\t\t\t\tReferencedContainer=\"container:GapSchedule.xcodeproj\">
\t\t\t</BuildableReference>
\t\t</BuildActionEntry>"""

    # 插入到最后一个 </BuildActionEntry> 之后、</BuildActionEntries> 之前
    scheme = scheme.replace(
        "</BuildActionEntries>",
        widget_entry + "\n\t\t</BuildActionEntries>"
    )
    with open(scheme_path, "w", encoding="utf-8") as f:
        f.write(scheme)
    print("xcscheme updated with Widget target")

# 保存
with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Widget target injected: {len(content)} bytes")
print("Widget target: GapScheduleWidget")
