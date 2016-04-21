import json
import os
import configparser
import base64
from flask import Flask
from flask import request

# 定义环境:test, develop, prodction
application_env = 'develop'
app = Flask(__name__)


@app.route('/upload', methods=['POST'])
def upload_path():
    # 判断是否为post请求，只接受post请求数据
    if request.method == 'POST':
        # 读取post的数据
        json_parameter = json.loads(bytes.decode(request.data))
        # 从base64编码转为二进制编码
        file_content = base64.b64decode(json_parameter['file_content'])
        # 获取文件保存目录
        file_path = os.path.join(os.path.abspath(''), 'img')
        # 拼接文件名
        file_name_arry = [json_parameter['name'], json_parameter['id_number'],json_parameter['file_name']]
        # 获取完整文件保存路径
        file_name = os.path.join(file_path, '_'.join(file_name_arry))
        # 写入文件并保存
        save_file = open(file_name, 'wb')
        save_file.write(file_content)
        save_file.close()
        # json_parameter=request.data
        return 'ok'
    return 'error'
if __name__ == '__main__':
    cf = configparser.ConfigParser()
    # 获取配置文件路径
    conf_path = os.path.join(os.path.abspath(''), 'conf')
    # 获取配置文件名
    config_file_path = os.path.join(conf_path, 'config.conf')
    # 读取配置文件
    cf.read(config_file_path)
    # 从配置文件中读取host和port
    application_host = cf.get(application_env, "host")
    application_port = int(cf.get(application_env, "port"))

    app.debug = True
    app.run(host=application_host, port=application_port)
