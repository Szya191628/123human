#!/usr/bin/env python3
"""List a local LiveTalking session or send one explicitly approved text message."""
from __future__ import annotations
import argparse
import json
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


def get_json(url: str, payload=None) -> dict:
    body = json.dumps(payload, ensure_ascii=False).encode('utf-8') if payload is not None else None
    headers = {'Content-Type': 'application/json'} if payload is not None else {}
    req = Request(url, data=body, headers=headers, method='POST' if payload is not None else 'GET')
    with urlopen(req, timeout=12) as resp:
        return json.loads(resp.read(200000).decode('utf-8'))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--base-url', default='http://127.0.0.1:8010', help='仅限本机 URL')
    p.add_argument('--list', action='store_true', help='查看正在运行的 Session（默认）')
    p.add_argument('--send', action='store_true', help='向已有 Session 发送一次测试话术')
    p.add_argument('--sessionid', help='在 LiveTalking 页面建立 WebRTC 连接后的 sessionid')
    p.add_argument('--text', default='你好，欢迎来到数字人直播联调。')
    a = p.parse_args()
    url = a.base_url.rstrip('/')
    if not (url.startswith('http://127.0.0.1:') or url.startswith('http://localhost:') or url.startswith('http://[::1]:')):
        p.error('本工具仅能访问 localhost；远端请先建立可信的 SSH tunnel')
    if a.send and not a.sessionid:
        p.error('--send 必须提供 --sessionid')
    if len(a.text) > 500:
        p.error('为避免误播，测试文本最多 500 字')
    try:
        if a.send:
            data = get_json(url+'/human', {'sessionid': a.sessionid, 'text': a.text, 'type': 'echo', 'interrupt': False})
        else:
            data = get_json(url+'/api/admin/sessions')
        print(json.dumps(data, ensure_ascii=False, indent=2))
        if data.get('code') != 0:
            raise SystemExit(1)
    except (HTTPError, URLError, TimeoutError, OSError, ValueError) as exc:
        raise SystemExit(f'接口调用失败: {exc}')


if __name__ == '__main__':
    main()
