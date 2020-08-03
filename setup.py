from setuptools import find_packages, setup

setup(
    name='dsc_datatool',
    version='1.0.0',
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    python_requires='>=3.6.8',
    install_requires=[
        'maxminddb>=1.3.0',
        'PyYAML>=3.12',
    ],
    extras_require={
        'dev': [
            'pytest>=4',
            'coverage',
            'watchdog',
        ],
    },
    entry_points={
        'console_scripts': [
            'dsc-datatool = dsc_datatool:main',
        ],
    },
    scripts=[
    ],
)
