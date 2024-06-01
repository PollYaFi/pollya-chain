import {
  Box,
  Divider,
  HStack,
  Heading,
  Icon,
  Link,
  Tab,
  TabList,
  TabPanel,
  TabPanels,
  Table,
  TableContainer,
  Tabs,
  Tag,
  Tbody,
  Td,
  Text,
  Th,
  Thead,
  Tr,
  useColorModeValue,
  useToast,
} from '@chakra-ui/react'
import { FiChevronRight, FiHome } from 'react-icons/fi'
import NextLink from 'next/link'
import Head from 'next/head'
import { useRouter } from 'next/router'
import { useEffect, useState } from 'react'
import { useSelector } from 'react-redux'
import {
  getAccount,
  getAllBalances,
  getBalanceStaked,
  getTxsBySender,
} from '@/rpc/query'
import { selectTmClient } from '@/store/connectSlice'
import { Account, Coin } from '@cosmjs/stargate'
import { TxSearchResponse } from '@cosmjs/tendermint-rpc'
import { toHex } from '@cosmjs/encoding'
import { TxBody } from 'cosmjs-types/cosmos/tx/v1beta1/tx'
import { trimHash, getTypeMsg, trimHashStr } from '@/utils/helper'
import { GetServerSideProps } from 'next'
import { connectRPCClient } from '@/rpc/client'

interface Tx {
    hash: string;
    height: number;
    messages: {
      typeUrl: string;
    }[],
    memo: string;
};

interface AccountProps {
   account: Account | null | undefined;
   balances: readonly Coin[] | null;
   balanceStaked: Coin | null | undefined;
   txSearch: {
      total: number;
      txs: Tx[]
  };
}

export default function DetailAccount(props: AccountProps) {
  const router = useRouter()
  const toast = useToast()
  const { address } = router.query
  const account = props.account;
  const txSearch = props.txSearch;
  const balanceStaked = props.balanceStaked;
  const balances = props.balances;

  const showError = (err: Error) => {
    const errMsg = err.message
    let error = null
    try {
      error = JSON.parse(errMsg)
    } catch (e) {
      error = {
        message: 'Invalid',
        data: errMsg,
      }
    }

    toast({
      title: error.message,
      description: error.data,
      status: 'error',
      duration: 5000,
      isClosable: true,
    })
  }

  const renderMessages = (messages: any) => {
    if (messages.length == 1) {
      return (
        <HStack>
          <Tag colorScheme="cyan">{getTypeMsg(messages[0].typeUrl)}</Tag>
        </HStack>
      )
    } else if (messages.length > 1) {
      return (
        <HStack>
          <Tag colorScheme="cyan">{getTypeMsg(messages[0].typeUrl)}</Tag>
          <Text textColor="cyan.800">+{messages.length - 1}</Text>
        </HStack>
      )
    }

    return ''
  }

  return (
    <>
      <Head>
        <title>Detail Account | Dexplorer</title>
        <meta name="description" content="Account | Dexplorer" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main>
        <HStack h="24px">
          <Heading size={'md'}>Account</Heading>
          <Divider borderColor={'gray'} size="10px" orientation="vertical" />
          <Link
            as={NextLink}
            href={'/'}
            style={{ textDecoration: 'none' }}
            _focus={{ boxShadow: 'none' }}
            display="flex"
            justifyContent="center"
          >
            <Icon
              fontSize="16"
              color={useColorModeValue('light-theme', 'dark-theme')}
              as={FiHome}
            />
          </Link>
          <Icon fontSize="16" as={FiChevronRight} />
          <Text>Accounts</Text>
          <Icon fontSize="16" as={FiChevronRight} />
          <Text>Detail</Text>
        </HStack>
        <Box
          mt={8}
          bg={useColorModeValue('light-container', 'dark-container')}
          shadow={'base'}
          borderRadius={4}
          p={4}
        >
          <Heading size={'md'} mb={4}>
            Profile
          </Heading>
          <Divider borderColor={'gray'} mb={4} />
          <TableContainer>
            <Table variant="unstyled" size={'sm'}>
              <Tbody>
                <Tr>
                  <Td pl={0} width={150}>
                    <b>Address</b>
                  </Td>
                  <Td>{address}</Td>
                </Tr>
                <Tr>
                  <Td pl={0} width={150}>
                    <b>Pub Key</b>
                  </Td>
                  <Td>
                    <Tabs>
                      <TabList>
                        <Tab>@Type</Tab>
                        <Tab>Key</Tab>
                      </TabList>
                      <TabPanels>
                        <TabPanel>
                          <p>{account?.pubkey?.type}</p>
                        </TabPanel>
                        <TabPanel>
                          <p>{account?.pubkey?.value}</p>
                        </TabPanel>
                      </TabPanels>
                    </Tabs>
                  </Td>
                </Tr>
                <Tr>
                  <Td pl={0} width={150}>
                    <b>Account Number</b>
                  </Td>
                  <Td>{account?.accountNumber}</Td>
                </Tr>
                <Tr>
                  <Td pl={0} width={150}>
                    <b>Sequence</b>
                  </Td>
                  <Td>{account?.sequence}</Td>
                </Tr>
              </Tbody>
            </Table>
          </TableContainer>
        </Box>

        <Box
          mt={8}
          bg={useColorModeValue('light-container', 'dark-container')}
          shadow={'base'}
          borderRadius={4}
          p={4}
        >
          <Heading size={'md'} mb={4}>
            Balances
          </Heading>
          <Heading size={'sm'} mb={4}></Heading>
          <Tabs size="md">
            <TabList>
              <Tab>Available</Tab>
              <Tab>Delegated</Tab>
            </TabList>
            <TabPanels>
              <TabPanel>
                <TableContainer>
                  <Table variant="simple">
                    <Thead>
                      <Tr>
                        <Th>Denom</Th>
                        <Th>Amount</Th>
                      </Tr>
                    </Thead>
                    <Tbody>
                      {balances?.map((item, index) => (
                        <Tr key={index}>
                          <Td>{item.denom}</Td>
                          <Td>{item.amount}</Td>
                        </Tr>
                      ))}
                    </Tbody>
                  </Table>
                </TableContainer>
              </TabPanel>
              <TabPanel>
                <TableContainer>
                  <Table variant="simple">
                    <Thead>
                      <Tr>
                        <Th>Denom</Th>
                        <Th>Amount</Th>
                      </Tr>
                    </Thead>
                    <Tbody>
                      <Tr>
                        <Td>{balanceStaked?.denom}</Td>
                        <Td>{balanceStaked?.amount}</Td>
                      </Tr>
                    </Tbody>
                  </Table>
                </TableContainer>
              </TabPanel>
            </TabPanels>
          </Tabs>
        </Box>

        <Box
          mt={8}
          bg={useColorModeValue('light-container', 'dark-container')}
          shadow={'base'}
          borderRadius={4}
          p={4}
        >
          <Heading size={'md'} mb={4}>
            Transactions
          </Heading>
          <Divider borderColor={'gray'} mb={4} />
          <TableContainer>
            <Table variant="simple">
              <Thead>
                <Tr>
                  <Th>Tx Hash</Th>
                  <Th>Messages</Th>
                  <Th>Memo</Th>
                  <Th>Height</Th>
                </Tr>
              </Thead>
              <Tbody>
                {txSearch.txs.map((tx) => (
                  <Tr key={tx.hash}>
                    <Td>
                      <Link
                        as={NextLink}
                        href={'/txs/' + tx.hash.toUpperCase()}
                        style={{ textDecoration: 'none' }}
                        _focus={{ boxShadow: 'none' }}
                      >
                        <Text
                          color={useColorModeValue('light-theme', 'dark-theme')}
                        >
                          {trimHashStr(tx.hash)}
                        </Text>
                      </Link>
                    </Td>
                    <Td>{renderMessages(tx.messages)}</Td>
                    <Td>{tx.memo}</Td>
                    <Td>
                      <Link
                        as={NextLink}
                        href={'/blocks/' + tx.height}
                        style={{ textDecoration: 'none' }}
                        _focus={{ boxShadow: 'none' }}
                      >
                        <Text
                          color={useColorModeValue('light-theme', 'dark-theme')}
                        >
                          {tx.height}
                        </Text>
                      </Link>
                    </Td>
                  </Tr>
                ))}
              </Tbody>
            </Table>
          </TableContainer>
        </Box>
      </main>
    </>
  )
}

export const getServerSideProps: GetServerSideProps<AccountProps> = async (context) => {
  //console.log(context);
  const { address } = context.query;
  const tmClient = await connectRPCClient("http://localhost:26657");
  const account = await getAccount(tmClient, address as string);
  const balances = await getAllBalances(tmClient, address as string);
  const balanceStaked = await getBalanceStaked(tmClient, address as string);
  const txSearch = await getTxsBySender(tmClient, address as string, 1, 30);
  const txs = txSearch.txs.map((tx) => {
     const body = TxBody.decode(tx?.result?.data || new Uint8Array());
     return {
       height: tx.height,
       hash: toHex(tx.hash),
       memo: body.memo,
       messages: body.messages.map((m) => {
        return {
         typeUrl: m.typeUrl
        };
       })
     }
  });
  return {
    props: {
      account,
      balances,
      balanceStaked,
      txSearch: {
        total: txSearch.totalCount,
        txs
      }
    },
  };
};

