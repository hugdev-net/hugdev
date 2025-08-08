import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait, Select
from selenium.webdriver.support import expected_conditions as EC

# 创建 Chrome 浏览器实例
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument("--start-maximized")  # 启动时最大化窗口
chrome_options.add_argument("--disable-extensions")  # 禁用扩展

# 指定 Chrome 浏览器可执行文件的路径
chrome_options.binary_location = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
chrome_driver_path = r"D:\Python\Python313\chromedriver-win64\chromedriver.exe"


def setImapSettings(email, password):
    # 管理 chrome 浏览器
    service = Service(chrome_driver_path)
    driver = webdriver.Chrome(service=service, options=chrome_options)

    # 打开指定网址
    url = "https://exmail.qq.com/login"  # 修改为你需要访问的网址
    driver.get(url)

    # 登录
    wait = WebDriverWait(driver, 30)
    wait.until(EC.element_to_be_clickable((By.LINK_TEXT, "其他方式登录"))).click()
    wait.until(EC.element_to_be_clickable((By.LINK_TEXT, "账号密码"))).click()

    input = driver.find_element(By.NAME, "inputuin")
    input.clear()
    input.send_keys(email)

    input = driver.find_element(By.NAME, "pp")
    input.clear()
    input.send_keys(password)

    btn = driver.find_element(By.NAME, "btlogin")
    ActionChains(driver).move_to_element(btn).click().perform()

    # 设置
    wait.until(EC.element_to_be_clickable((By.LINK_TEXT, "设置"))).click()
    wait.until(EC.frame_to_be_available_and_switch_to_it((By.ID, "mainFrame")))
    wait.until(EC.element_to_be_clickable((By.LINK_TEXT, "客户端设置"))).click()

    # 选项
    select = wait.until(EC.element_to_be_clickable((By.NAME, "poprecent")))
    driver.execute_script("arguments[0].scrollIntoView(true);", select)
    Select(select).select_by_visible_text("全部")
    time.sleep(1)

    # 点击保存按钮
    btn = driver.find_element(By.LINK_TEXT, "保存更改")
    ActionChains(driver).move_to_element(btn).click().perform()

    # 关闭浏览器
    time.sleep(1)
    driver.quit()


if __name__ == "__main__":
    setImapSettings("demo@test.com", "passwd")
