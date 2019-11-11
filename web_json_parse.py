# coding=utf-8

import sys
import json
from urllib.request import urlopen
from distutils.version import LooseVersion

"""
download json index of node.js distributions
Parameters:
    <arg0>: self (name of program/file) -> String
    <arg1>: URL for json source -> String
    <arg2>: OS arch -> String
    <arg3>: command -> String

"""
node_url = sys.argv[1]
os_arch = sys.argv[2]


def get_response(url):
    """
    Fetch json data from target URL
    :param url: url string for json source
    :return: raw json data
    """
    open_url = urlopen(url)
    if open_url.getcode() == 200:
        data = open_url.read()
        json_data = json.loads(data)
        return json_data
    else:
        print("Error receiving data from nodejs.org", open_url.getcode())


def filter_arch_compatible(data, os_filter):
    """
    Filter out incompatible versions of node.js from available distributions
    :param data: json data fetched from nodejs.org
    :param os_filter: filter for json data -> String
    :return: filtered json data after extracting desired fields
    """
    tmp_data = []

    for item in data:
        if os_filter in item['files']:
            tmp_data.append(item)

    if not tmp_data:
        print("No suitable node.js versions/candidates found")
        return
    return tmp_data


def version_compare(version1, version2):
    """
    Compare versions of node.js
    :param version1: version of node.js -> String
    :param version2: version of node.js -> String
    :return: higher version number -> String
    """
    version1_no_v = version1[1:]
    version2_no_v = version2[1:]
    return version1 if LooseVersion(version1_no_v) > LooseVersion(version2_no_v) else version2


def get_latest_lts(data, lts_name):
    """
    Get latest version of for said LTS
    :param data: json data from node.js
    :param lts_name: name of LTS version requested -> String
    :return: latest node.js version number for LTS requested -> String
    """
    item_version = 'v0'
    for item in data:
        if item['lts'] == lts_name:
            item_version = version_compare(item_version, item['version'])

    return item_version


def get_lts(data):
    """
    List LTS versions of node.js
        Just prints list of available versions
    :param data: json data fetched from nodejs.org
    :return: NOTHING YET, maybe later
    """
    for item in data:
        if item['lts']:
            print('node.js %s, LTS: %s (npm v%s)' % (item['version'], item['lts'], item['npm']))


def get_all_versions(data):
    """
    List all available versions of node.js
        Just prints list of available versions
    :param data: json data fetched from nodejs.org
    :return: NOTHING YET, maybe later
    """
    for item in data:
        if item['lts']:
            if 'npm' in item:
                print('node.js %s,   (npm v%s)   LTS: %s' % (item['version'], item['npm'], item['lts']))
            else:
                print('node.js %s,   LTS: %s' % (item['version'], item['lts']))
        else:
            if 'npm' in item:
                print('node.js %s,   (npm v%s)' % (item['version'], item['npm']))
            else:
                print('node.js %s' % (item['version']))


def get_lts_names(data):
    """
    List all LTS version codenames for node.js
        Just prints list of available versions
    :param data: json data fetched from nodejs.org
    :return: NOTHING YET, maybe later
    """
    lts_list = []

    for item in data:
        if (item['lts']) and (item['lts'] not in lts_list):
            lts_list.append(item['lts'])
    print(lts_list)


if __name__ == '__main__':
    nodeVersions = get_response(node_url)
    nodeVersions = filter_arch_compatible(nodeVersions, os_arch)
    # get_lts_names(nodeVersions)

    # print(version_compare('1.15.1b', '1.15.2'))
    # print(get_latest_lts(nodeVersions, 'Carbon'))

    if nodeVersions:
        if sys.argv[3] == 'ls_all':
            get_all_versions(nodeVersions)
        elif sys.argv[3] == 'ls_lts':
            get_lts(nodeVersions)
