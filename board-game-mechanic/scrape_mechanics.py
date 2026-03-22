#!/usr/bin/env python3
"""
從本地 HTML 檔案爬取 BoardGameGeek 桌遊機制清單
"""

from bs4 import BeautifulSoup
import re
from urllib.parse import urljoin
import os

def scrape_bgg_mechanics_from_html():
    """從本地 HTML 檔案爬取機制清單"""
    # 使用當前腳本所在目錄的路徑
    script_dir = os.path.dirname(os.path.abspath(__file__))
    html_file = os.path.join(script_dir, "Browse Board Game Mechanics _ BoardGameGeek.html")
    
    if not os.path.exists(html_file):
        print(f"錯誤: 找不到檔案 {html_file}")
        print(f"當前目錄: {os.getcwd()}")
        print(f"嘗試的檔案路徑: {html_file}")
        return []
    
    print(f"正在從本地檔案 {html_file} 爬取機制清單...")
    
    try:
        # 嘗試不同的編碼
        try:
            with open(html_file, 'r', encoding='utf-8') as f:
                html_content = f.read()
        except UnicodeDecodeError:
            with open(html_file, 'r', encoding='latin-1') as f:
                html_content = f.read()
        
        soup = BeautifulSoup(html_content, 'html.parser')
        
        # 尋找機制表格
        mechanics = []
        
        # 方法1：尋找表格中的連結
        table = soup.find('table', class_='forum_table')
        if table:
            links = table.find_all('a', href=re.compile(r'/boardgamemechanic/\d+/'))
            for link in links:
                href = link.get('href')
                name = link.text.strip()
                full_url = urljoin('https://boardgamegeek.com', href)
                
                mechanics.append({
                    'name': name,
                    'url': full_url,
                    'id': re.search(r'/boardgamemechanic/(\d+)/', href).group(1) if re.search(r'/boardgamemechanic/(\d+)/', href) else ''
                })
        
        # 方法2：如果表格沒找到，嘗試其他方式
        if not mechanics:
            # 尋找所有包含機制連結的元素
            all_links = soup.find_all('a', href=True)
            for link in all_links:
                href = link.get('href')
                if '/boardgamemechanic/' in href and link.text.strip():
                    name = link.text.strip()
                    full_url = urljoin('https://boardgamegeek.com', href)
                    
                    mechanics.append({
                        'name': name,
                        'url': full_url,
                        'id': re.search(r'/boardgamemechanic/(\d+)/', href).group(1) if re.search(r'/boardgamemechanic/(\d+)/', href) else ''
                    })
        
        # 方法3：尋找所有可能的機制名稱
        if not mechanics:
            print("嘗試尋找所有可能的機制名稱...")
            # 尋找所有文字內容
            for element in soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'div', 'span', 'li', 'td', 'th']):
                text = element.get_text().strip()
                if text and 2 < len(text) < 100:  # 合理的機制名稱長度
                    # 檢查是否可能是機制名稱（排除常見的非機制文字）
                    excluded_terms = ['BoardGameGeek', 'Browse', 'Mechanics', 'Home', 'Search', 'Login', 'Register', 'Help']
                    if not any(term in text for term in excluded_terms):
                        # 檢查是否有機制相關的關鍵字
                        mechanic_keywords = ['Action', 'Dice', 'Card', 'Tile', 'Worker', 'Auction', 'Drafting', 'Placement', 'Management', 'Collection', 'Movement', 'Rolling', 'Building', 'Game', 'Player', 'Resource', 'Trading', 'Voting', 'Role', 'Pattern', 'Memory', 'Hidden', 'Cooperative', 'Simultaneous', 'Variable', 'Set', 'Take', 'Trick', 'Push', 'Pick-up', 'Pattern', 'Modular', 'Grid', 'Area', 'Point', 'Real-Time', 'Scenario', 'Solo', 'Team', 'Tech', 'Track', 'Traitor', 'Tug', 'Zone', 'Control']
                        
                        if any(keyword.lower() in text.lower() for keyword in mechanic_keywords):
                            # 嘗試找到對應的連結
                            parent = element.find_parent('a', href=re.compile(r'/boardgamemechanic/\d+/'))
                            if parent:
                                href = parent.get('href')
                                full_url = urljoin('https://boardgamegeek.com', href)
                                mechanics.append({
                                    'name': text,
                                    'url': full_url,
                                    'id': re.search(r'/boardgamemechanic/(\d+)/', href).group(1) if re.search(r'/boardgamemechanic/(\d+)/', href) else ''
                                })
                            else:
                                mechanics.append({
                                    'name': text,
                                    'url': 'https://boardgamegeek.com/browse/boardgamemechanic',
                                    'id': ''
                                })
        
        # 去重複
        unique_mechanics = []
        seen = set()
        for mech in mechanics:
            if mech['name'] not in seen:
                seen.add(mech['name'])
                unique_mechanics.append(mech)
        
        print(f"找到 {len(unique_mechanics)} 個機制")
        
        # 按名稱排序
        unique_mechanics.sort(key=lambda x: x['name'].lower())
        
        return unique_mechanics
        
    except Exception as e:
        print(f"爬取失敗: {e}")
        return []

def assign_priority(mechanic_name):
    """根據機制名稱分配優先級"""
    high_priority = [
        'Dice Rolling', 'Hand Management', 'Set Collection', 'Action Points',
        'Grid Movement', 'Roll / Spin and Move', 'Deck, Bag, and Pool Building',
        'Victory Points as a Resource', 'Player Elimination', 'Tile Placement'
    ]
    
    medium_priority = [
        'Worker Placement', 'Area Majority / Influence', 'Auction / Bidding',
        'Card Drafting', 'Resource Management', 'Network and Route Building',
        'Trading', 'Voting', 'Variable Player Powers', 'Hidden Roles',
        'Simultaneous Action Selection', 'Push Your Luck', 'Take That',
        'Pattern Building', 'Cooperative Game'
    ]
    
    if mechanic_name in high_priority:
        return '高（第 1 階段）'
    elif mechanic_name in medium_priority:
        return '中（第 2 階段）'
    else:
        return '低（第 3+ 階段）'

def create_markdown_file(mechanics):
    """建立 Markdown 檔案"""
    markdown_content = """# BoardGameGeek 桌遊機制完整清單

## 說明

此文件列出 BoardGameGeek (BGG) 網站上的所有桌遊機制，共 **{} 種**。每個機制包含：
- 英文名稱（BGG 原始名稱）
- BGG 連結
- 實作狀態
- 優先級（高/中/低）

## 優先級定義

### 高優先級（第 1 階段 - 10 個核心機制）
最常見、最基礎的桌遊機制，適合先實作

### 中優先級（第 2 階段 - 15 個策略機制）
常見的策略機制，遊戲設計中常用

### 低優先級（第 3+ 階段）
特殊或較少見的機制

## 完整機制清單（按字母排序）

""".format(len(mechanics))
    
    # 按字母分組
    current_letter = ''
    for mech in mechanics:
        first_letter = mech['name'][0].upper()
        if first_letter != current_letter:
            markdown_content += f"\n### {first_letter}\n"
            current_letter = first_letter
        
        priority = assign_priority(mech['name'])
        
        markdown_content += f"- **{mech['name']}**\n"
        markdown_content += f"  - 連結: {mech['url']}\n"
        markdown_content += f"  - 狀態: 未實作\n"
        markdown_content += f"  - 優先級: {priority}\n\n"
    
    # 添加統計資訊
    high_count = sum(1 for m in mechanics if assign_priority(m['name']) == '高（第 1 階段）')
    medium_count = sum(1 for m in mechanics if assign_priority(m['name']) == '中（第 2 階段）')
    low_count = sum(1 for m in mechanics if assign_priority(m['name']) == '低（第 3+ 階段）')
    
    markdown_content += f"""
## 統計資訊

- 總機制數量: {len(mechanics)}
- 高優先級: {high_count}
- 中優先級: {medium_count}
- 低優先級: {low_count}

## 更新記錄

- 2026-03-22: 從本地 HTML 檔案爬取完整機制清單
"""
    
    return markdown_content

def main():
    """主函數"""
    print("開始從本地 HTML 檔案爬取 BoardGameGeek 機制清單...")
    
    mechanics = scrape_bgg_mechanics_from_html()
    
    if not mechanics:
        print("無法爬取機制清單，請檢查 HTML 檔案內容")
        return
    
    print(f"成功爬取 {len(mechanics)} 個機制")
    
    # 建立 Markdown 檔案
    markdown_content = create_markdown_file(mechanics)
    
    # 寫入檔案
    output_file = "MECHANICS_LIST.md"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(markdown_content)
    
    print(f"已建立 {output_file}")
    
    # 顯示統計資訊
    high_count = sum(1 for m in mechanics if assign_priority(m['name']) == '高（第 1 階段）')
    medium_count = sum(1 for m in mechanics if assign_priority(m['name']) == '中（第 2 階段）')
    low_count = sum(1 for m in mechanics if assign_priority(m['name']) == '低（第 3+ 階段）')
    
    print(f"\n統計資訊:")
    print(f"- 總機制數量: {len(mechanics)}")
    print(f"- 高優先級（第 1 階段）: {high_count}")
    print(f"- 中優先級（第 2 階段）: {medium_count}")
    print(f"- 低優先級（第 3+ 階段）: {low_count}")

if __name__ == "__main__":
    main()