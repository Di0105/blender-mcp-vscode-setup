"""
示例脚本：通过 Socket 直接向 Blender MCP 插件发送 Python 代码
（此脚本不依赖 MCP Server，直接与 Blender 插件通信）

使用前请确保：
1. Blender 已打开
2. Blender MCP 插件已启用并连接（显示 "Running on port 9876"）

原项目: https://github.com/ahujasid/blender-mcp (MIT License, by Siddharth Ahuja)
"""

import socket
import json


def send_to_blender(code: str, host: str = "localhost", port: int = 9876) -> dict:
    """
    向 Blender MCP 插件发送 Python 代码并获取结果。

    Args:
        code: 要在 Blender 中执行的 Python 代码
        host: Blender 插件监听地址（默认 localhost）
        port: Blender 插件监听端口（默认 9876）

    Returns:
        Blender 返回的 JSON 响应
    """
    command = json.dumps({
        "type": "execute_code",
        "params": {"code": code}
    })

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(30)
        sock.connect((host, port))
        sock.sendall(command.encode("utf-8"))

        # 接收响应
        chunks = []
        while True:
            try:
                chunk = sock.recv(8192)
                if not chunk:
                    break
                chunks.append(chunk)
                # 尝试解析，成功则停止接收
                try:
                    json.loads(b"".join(chunks).decode("utf-8"))
                    break
                except json.JSONDecodeError:
                    continue
            except socket.timeout:
                break

        response = b"".join(chunks).decode("utf-8")
        return json.loads(response)


# ─── 示例：创建一个简单的雪山场景 ───

if __name__ == "__main__":
    print("正在向 Blender 发送场景创建代码...")

    scene_code = """
import bpy
import math

# 清空场景
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# 创建地面平面
bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
ground = bpy.context.active_object
ground.name = "Ground"

# 地面材质 - 草地
mat_ground = bpy.data.materials.new(name="Grass")
mat_ground.use_nodes = True
bsdf = mat_ground.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value = (0.15, 0.35, 0.1, 1.0)
bsdf.inputs["Roughness"].default_value = 0.9
ground.data.materials.append(mat_ground)

# 创建一个简单的"山"（锥体）
bpy.ops.mesh.primitive_cone_add(
    vertices=32, radius1=4, radius2=0.3, depth=6,
    location=(0, 0, 3)
)
mountain = bpy.context.active_object
mountain.name = "Mountain"

# 山体材质 - 岩石色
mat_rock = bpy.data.materials.new(name="Rock")
mat_rock.use_nodes = True
bsdf = mat_rock.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value = (0.35, 0.3, 0.25, 1.0)
bsdf.inputs["Roughness"].default_value = 0.95
mountain.data.materials.append(mat_rock)

# 雪顶材质（顶部用白色覆盖）
bpy.ops.mesh.primitive_cone_add(
    vertices=32, radius1=1.5, radius2=0.2, depth=2,
    location=(0, 0, 5.5)
)
snow_cap = bpy.context.active_object
snow_cap.name = "SnowCap"

mat_snow = bpy.data.materials.new(name="Snow")
mat_snow.use_nodes = True
bsdf = mat_snow.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value = (0.95, 0.97, 1.0, 1.0)
bsdf.inputs["Roughness"].default_value = 0.8
snow_cap.data.materials.append(mat_snow)

# 添加太阳灯
bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
sun = bpy.context.active_object
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(45), 0, math.radians(45))

# 设置相机
bpy.ops.object.camera_add(location=(10, -10, 6))
camera = bpy.context.active_object
camera.rotation_euler = (math.radians(65), 0, math.radians(45))
bpy.context.scene.camera = camera

print("场景创建完成！")
"""

    result = send_to_blender(scene_code)

    if result.get("status") == "ok":
        print("✓ 场景创建成功！请查看 Blender 窗口。")
    else:
        print(f"✗ 出错了: {result.get('message', '未知错误')}")
