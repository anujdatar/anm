# coding=utf-8
import sys
import json
from urllib.request import urlopen
from packaging.version import Version
from urllib3 import Retry

"""
download and parse json index of node.js distributions
param: <arg0>: str -> self (name of program/file)
param: <arg1>: str -> URL for json source
param: <arg2>: str -> OS architecture
param: <arg3>: str -> command

"""


def fetch_node_version_data(url):
    """
    Fetch json data from target URL
    :param url: str -> url string for json source
    :return: json -> raw json data from nodejs.org
    """
    open_url = urlopen(url)
    if open_url.getcode() == 200:
        data = open_url.read()
        json_data = json.loads(data)
        return json_data
    else:
        print('Error receiving data from nodejs.org', open_url.getcode())


def filter_arch_compatible(data, os_filter):
    """
    Filter out incompatible versions of node.js from available distributions
    :param data: list -> json data fetched from nodejs.org
    :param os_filter: str -> filter for json data
    :return: filtered json data after extracting desired fields
    """
    tmp_data = []

    for item in data:
        if os_filter in item['files']:
            tmp_data.append(item)

    if not tmp_data:
        print('No suitable node.js versions/candidates found')
        return
    return tmp_data


def version_compare(item1, item2):
    """
    Compare versions of node.js
    :param item1: dict -> dictionary item for a node version
    :param item2: dict -> dictionary item for a node version
    :return: dict -> dictionary item with higher node version
    """
    version1_no_v = item1['version'][1:]
    version2_no_v = item2['version'][1:]
    return item1 if Version(version1_no_v) > Version(version2_no_v) else item2


def get_major_version(item):
    """
    Get major version number from item dictionary
    :param item: dict -> version number string
    :return: int -> major version number
    """
    return Version(item['version'][1:]).major


def print_node_version_data(item):
    """
    Format and print node version data
    :param item: dict -> json dict item from data fetched from nodejs.org
    :return: None. just console print data
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


def print_all_versions(data):
    """
    Console print list of compatible data
    :param data: lit[dict] -> json data fetched from nodejs.org
    :return: None, just console print formatted data
    """
    for item in data:
        print_node_version_data(item)


def print_all_lts_versions(data):
    """
    List compatible LTS versions of node.js
        Just prints list of available versions
    :param data: list[dict] -> json data fetched from nodejs.org
    :return: None, just console print formatted data
    """
    for item in data:
        if item['lts']:
            print_node_version_data(item)


def get_latest_all(data):
    """
    List latest revisions of all compatible versions of node.js
    :param data: list[dict] -> json data fetched from nodejs.org
    :return: list[dict] -> containing the latest versions of each node release
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

    return list_latest_versions


def print_latest_all(data):
    """
    Print all latest node release version data
    :param data: list[dict] -> json data fetched from nodejs.org
    : return: None
    """
    latest_version_data = get_latest_all(data)
    for item in latest_version_data:
        print_node_version_data(item)


def get_all_lts_names(data):
    """
    List all LTS version codenames for node.js
        Just prints list of available versions
    :param data: list[dict] -> json data fetched from nodejs.org
    :return: list[str] -> list of LTS version code names
    """
    lts_list = []

    for item in data:
        if (item['lts']) and (item['lts'] not in lts_list):
            lts_list.append(item['lts'].lower())
    return lts_list


def print_latest_lts_version_data(data, lts_name):
    """
    Get latest version data of for said LTS name
    :param data: list[dict] -> json data from node.js
    :param lts_name: str -> name of LTS version requested
    :return: None -> latest node.js version number for LTS requested
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
        print('Error!! Invalid LTS version name: %s' % lts_name)
        sys.exit(1)
    print_node_version_data(last_item)


def print_latest_lts_version_number(data, lts_name):
    """
    Get just latest version number of said LTS name
    :param data: list[dict] -> json data from node.js
    :param lts_name: str -> name of LTS version requested
    :return: None | Error -> latest node.js version number for LTS requested
    """
    lts_names_list = get_all_lts_names(data)
    latest_version_data = get_latest_all(nodeVersions)

    if not lts_name:
        latest_version = {}
        for item in latest_version_data:
            if not latest_version:
                latest_version = item
            else:
                latest_version = version_compare(item, latest_version)
        print(latest_version['version'])
    elif lts_name == 'latest_lts':
        latest_version = {}
        for item in latest_version_data:
            if item['lts']:
                if not latest_version:
                    latest_version = item
                else:
                    latest_version = version_compare(item, latest_version)
        print(latest_version['version'])
    elif lts_name.lower() in lts_names_list:
        for item in latest_version_data:
            if lts_name.capitalize() == item['lts']:
                print(item['version'])
    else:
        print('Unknown node lts version')
        sys.exit(1)


if __name__ == '__main__':
    node_url = sys.argv[1]
    os_arch = sys.argv[2]

    nodeVersions = fetch_node_version_data(node_url)
    nodeVersions = filter_arch_compatible(nodeVersions, os_arch)

    if nodeVersions:
        if len(sys.argv)-1 >= 3:
            if sys.argv[3] == 'ls_all':
                print_all_versions(nodeVersions)
            elif sys.argv[3] == 'ls_lts':
                print_all_lts_versions(nodeVersions)
            elif sys.argv[3] == 'ls_latest':
                print_latest_all(nodeVersions)
            elif sys.argv[3] == 'lts_latest_data':
                print_latest_lts_version_data(nodeVersions, sys.argv[4])
            elif sys.argv[3] == 'lts_latest_number':
                print_latest_lts_version_number(nodeVersions, sys.argv[4])
