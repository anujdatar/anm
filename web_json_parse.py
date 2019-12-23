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


def version_compare(item1, item2):
    """
    Compare versions of node.js
    :param item1: dictionary item for a node version -> Dictionary
    :param item2: dictionary item for a node version -> Dictionary
    :return: dictionary item with higher node version -> Dictionary
    """
    version1_no_v = item1['version'][1:]
    version2_no_v = item2['version'][1:]
    return item1 if LooseVersion(version1_no_v) > LooseVersion(version2_no_v) else item2


def get_major_version(item):
    """
    Get major version number from item dictionary
    :param item: version number string -> Dictionary
    :return: major version number -> generally Integer
    """
    return LooseVersion(item['version'][1:]).version[0]


def print_node_version_data(item):
    """
    Format and print node version data
    :param item: json item from data fetched from nodejs.org
    :return: NOTHING. just console print data
    """
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


def get_all_versions(data):
    """
    Console print list of compatible data
    :param data: json data fetched from nodejs.org
    :return: NOTHING, just console print formatted data
    """
    for item in data:
        print_node_version_data(item)


def get_lts_versions(data):
    """
    List compatible LTS versions of node.js
        Just prints list of available versions
    :param data: json data fetched from nodejs.org
    :return: NOTHING, just console print formatted data
    """
    for item in data:
        if item['lts']:
            print_node_version_data(item)


def get_latest_all(data):
    """
    List latest revisions of all compatible versions of node.js
    :param data: json data fetched from nodejs.org
    :return: NOTHING YET, maybe later
    """
    list_latest_versions = []
    last_item = {}
    for item in data:
        if not last_item:
            last_item = item
        if get_major_version(item) == get_major_version(last_item):
            last_item = version_compare(item, last_item)
            if last_item not in list_latest_versions:
                list_latest_versions.append(last_item)
        else:
            last_item = item

    # return list_latest_versions
    # print(list_latest_versions)
    for x in list_latest_versions:
        print_node_version_data(x)


def get_lts_names(data):
    """
    List all LTS version codenames for node.js
        Just prints list of available versions
    :param data: json data fetched from nodejs.org
    :return: lts_list: list of LTS version code names -> List of Strings
    """
    lts_list = []

    for item in data:
        if (item['lts']) and (item['lts'] not in lts_list):
            lts_list.append(item['lts'])
    return lts_list


def get_latest_lts(data, lts_name):
    """
    Get latest version of for said LTS
    :param data: json data from node.js
    :param lts_name: name of LTS version requested -> String
    :return: latest node.js version number for LTS requested -> String
    """
    last_item = {}
    for item in data:
        if not item['lts']:
            continue
        if item['lts'].lower() == lts_name.lower():
            if not last_item:
                last_item = item
            last_item = version_compare(last_item, item)

    if not last_item:
        # print("Error!! Invalid LTS version name: %s" % lts_name)
        return -1
    return last_item


if __name__ == '__main__':
    nodeVersions = get_response(node_url)
    nodeVersions = filter_arch_compatible(nodeVersions, os_arch)

    # print(get_latest_lts(nodeVersions, 'Erbium'))

    # print(get_major_version("v8.0.15a"))
    # print(get_major_version("v99999"))

    # get_latest_all(nodeVersions )

    if nodeVersions:
        if len(sys.argv)-1 >= 3:
            if sys.argv[3] == 'ls_all':
                get_all_versions(nodeVersions)
            elif sys.argv[3] == 'ls_lts':
                get_lts_versions(nodeVersions)
            elif sys.argv[3] == 'ls_latest':
                get_latest_all(nodeVersions)
            elif sys.argv[3] == 'lts_latest':
                print(get_latest_lts(nodeVersions, sys.argv[4]))
