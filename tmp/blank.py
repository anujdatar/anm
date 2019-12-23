def get_latest_all(data):
    """
    List latest revisions of all compatible versions of node.js
    :param data: json data fetched from nodejs.org
    :return: NOTHING YET, maybe later
    """
    list_latest_versions = []
    dummy = []
    last_version = ''
    newer = ''
    for item in data:
        if not last_version:
            last_version = item['version']
        if get_major_version(item['version']) == get_major_version(last_version):
            newer = version_compare(last_version, item['version'])
        else:
            if newer not in list_latest_versions:
                list_latest_versions.append(newer)
                dummy.append(item)
            last_version = item['version']

    # for item in data:

    print(list_latest_versions)
    for x in dummy:
        print_node_version_data(x)