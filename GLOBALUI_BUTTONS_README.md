# GlobalUI 新增按钮说明

## 已完成的工作

### 1. 场景文件修改 (GlobalUI.tscn)
- 在 `TopHUD` 下添加了 `RightButtons` HBoxContainer 容器
- 添加了两个按钮：
  - `DeckIconButton` - 卡组按钮
  - `SettingsButton` - 设置按钮
- 每个按钮都包含一个 `IconTexture` TextureRect 用于显示图标
- 添加了按钮点击信号连接

### 2. 脚本文件修改 (global_ui.gd)
- 添加了两个按钮的引用：
  ```gdscript
  @onready var deck_icon_button: Button = $TopHUD/RightButtons/DeckIconButton
  @onready var settings_button: Button = $TopHUD/RightButtons/SettingsButton
  ```
- 添加了两个回调函数：
  - `_on_deck_icon_button_pressed()` - 打开卡组面板
  - `_on_settings_button_pressed()` - 打开暂停菜单（设置）

### 3. 占位贴图
创建了两个占位贴图文件：
- `res://assets/art/ui/global/btn_deck_placeholder.png` - 卡组按钮占位图
- `res://assets/art/ui/global/btn_settings_placeholder.png` - 设置按钮占位图

## 如何替换成你的图标

### 步骤 1: 准备你的图标
- 建议尺寸：64x64 像素（或更高分辨率，会自动缩放）
- 格式：PNG（支持透明背景）
- 风格：与游戏 UI 保持一致

### 步骤 2: 替换贴图文件
将你的图标文件保存到以下位置（覆盖占位文件）：
```
res://assets/art/ui/global/btn_deck_placeholder.png    - 卡组图标
res://assets/art/ui/global/btn_settings_placeholder.png - 设置图标
```

或者：
1. 将你的图标文件放到 `res://assets/art/ui/global/` 目录
2. 打开 `GlobalUI.tscn` 文件
3. 修改贴图资源路径：
   ```
   [ext_resource type="Texture2D" uid="uid://bt7w5xq2z0kde" path="res://assets/art/ui/global/你的卡组图标.png" id="5_deck_icon"]
   [ext_resource type="Texture2D" uid="uid://c9y3k8p1m4nxf" path="res://assets/art/ui/global/你的设置图标.png" id="6_settings_icon"]
   ```

### 步骤 3: 在 Godot 编辑器中刷新
- 打开 Godot 编辑器
- 切换到 `GlobalUI.tscn` 场景
- 如果 Godot 提示更新资源，确认更新

## 按钮功能

### 卡组按钮 (DeckIconButton)
- **位置**: TopHUD 右侧
- **功能**: 点击后打开卡组面板，显示当前牌库中的所有卡牌
- **关联**: 与现有的 DeckPanel 联动

### 设置按钮 (SettingsButton)
- **位置**: TopHUD 右侧，卡组按钮旁边
- **功能**: 点击后打开暂停菜单
- **包含选项**:
  - 返回游戏
  - 设置
  - 保存并退出
  - 返回基地
  - 退出游戏

## 调整按钮位置（可选）

如果需要调整按钮的位置，在 `GlobalUI.tscn` 中修改 `RightButtons` 节点的属性：

```
[node name="RightButtons" type="HBoxContainer" parent="TopHUD"]
offset_left = 280.0    # 调整左右位置
offset_top = -24.0     # 调整上下位置
offset_right = 420.0   # 调整宽度
offset_bottom = 24.0   # 调整高度
```

## 调整按钮大小（可选）

如果需要调整按钮的大小，修改每个按钮的 `custom_minimum_size` 属性：

```
[node name="DeckIconButton" type="Button"]
custom_minimum_size = Vector2(60, 60)  # 修改为需要的尺寸

[node name="SettingsButton" type="Button"]
custom_minimum_size = Vector2(60, 60)  # 修改为需要的尺寸
```

## 测试

运行游戏，切换到使用 GlobalUI 的场景（如 BaseScene 或 ExploreScene），应该能在顶部 HUD 的右侧看到两个按钮。

点击测试：
- 点击卡组按钮 → 应该弹出卡组面板
- 点击设置按钮 → 应该打开暂停菜单
